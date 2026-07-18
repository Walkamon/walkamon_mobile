import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../models/step_sensor_models.dart';
import '../repositories/daily_step_repository.dart';
import 'android_step_bridge.dart';
import 'step_tracking_store.dart';

typedef CurrentTimeProvider = DateTime Function();
typedef NativeMotionStreamFactory = Stream<NativeMotionEvent> Function();
typedef ActivityPermissionChecker = Future<bool> Function();

class StepTrackingService extends WidgetsBindingObserver {
  StepTrackingService({
    StepTrackingStore? store,
    DailyStepRepository? repository,
    AndroidStepBridge? androidBridge,
    NativeMotionStreamFactory? motionStreamFactory,
    ActivityPermissionChecker? activityPermissionChecker,
    CurrentTimeProvider? currentTimeProvider,
    this.syncInterval = const Duration(seconds: 5),
  }) : _store = store ?? StepTrackingStore(),
       _repository = repository ?? DailyStepRepository(),
       _androidBridge = androidBridge ?? AndroidStepBridge(),
       _motionStreamFactory =
           motionStreamFactory ?? AndroidStepBridge.motionEvents,
       _activityPermissionChecker =
           activityPermissionChecker ??
           (() => Permission.activityRecognition.isGranted),
       _currentTimeProvider = currentTimeProvider ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
  }

  static const _vietnamUtcOffset = Duration(hours: 7);

  final StepTrackingStore _store;
  final DailyStepRepository _repository;
  final AndroidStepBridge _androidBridge;
  final NativeMotionStreamFactory _motionStreamFactory;
  final ActivityPermissionChecker _activityPermissionChecker;
  final CurrentTimeProvider _currentTimeProvider;
  final Duration syncInterval;

  StreamSubscription<NativeMotionEvent>? _motionSubscription;
  Future<void> _operationQueue = Future<void>.value();

  String? _activeUserId;
  String? _stepDate;
  int _dailyTotalSteps = 0;
  StepSensorSession? _session;
  bool _backgroundRunning = false;
  bool _disposed = false;

  ValueChanged<int>? onStepsChanged;

  int get currentStepCount => _dailyTotalSteps;
  String? get activeUserId => _activeUserId;
  bool get isTracking => _backgroundRunning;

  Future<void> startForUser(String userId) async {
    if (kIsWeb || _disposed || userId.isEmpty) return;
    if (_activeUserId == userId) {
      await resumeTracking();
      return;
    }

    try {
      if (_activeUserId != null) {
        await stopForUser();
      }
      _activeUserId = userId;
      final today = _formatVietnamDate(_currentTimeProvider());
      final storedState = await _store.loadState(userId);
      if (storedState != null && storedState.stepDate == today) {
        _stepDate = storedState.stepDate;
        _dailyTotalSteps = storedState.dailyTotalSteps;
        _session = storedState.session?.isExpired == false
            ? storedState.session
            : null;
      } else {
        await _resetForDate(today);
      }

      onStepsChanged?.call(_dailyTotalSteps);
      await resumeTracking();
    } catch (error) {
      debugPrint('Step tracking start failed: $error');
    }
  }

  Future<void> resumeTracking() async {
    if (kIsWeb) return;
    if (_disposed || _activeUserId == null) return;
    if (!await _activityPermissionChecker()) return;

    await _operationQueue;
    _motionSubscription ??= _motionStreamFactory().listen(
      (event) => _enqueue(() => _handleNativeEvent(event)),
      onError: (Object error) {
        debugPrint('Background step status stream failed: $error');
      },
    );

    final nativeStatus = await _androidBridge.getTrackingStatus();
    if (nativeStatus.running && nativeStatus.userId == _activeUserId) {
      _backgroundRunning = true;
      _dailyTotalSteps = nativeStatus.acceptedTotal;
      onStepsChanged?.call(_dailyTotalSteps);
      return;
    }

    await _ensureSession();
    final session = _session;
    if (session == null) return;
    final preferences = await SharedPreferences.getInstance();
    final accessToken = preferences.getString('access_token');
    if (accessToken == null || accessToken.isEmpty) return;

    await _androidBridge.startCollector(
      userId: _activeUserId!,
      stepDate: _stepDate!,
      apiBaseUrl: ApiConstants.baseUrl,
      accessToken: accessToken,
      mode: session.mode,
      policy: session.motionPolicy,
      session: session,
      acceptedTotal: _dailyTotalSteps,
    );
    _backgroundRunning = true;
  }

  Future<void> pauseTracking() async {
    if (kIsWeb) return;
    // The Android health foreground service intentionally keeps running.
  }

  Future<void> stopForUser() async {
    if (kIsWeb) return;
    await _androidBridge.stopCollector();
    await _cancelSensorSubscription();
    await _operationQueue;

    _backgroundRunning = false;
    _activeUserId = null;
    _stepDate = null;
    _dailyTotalSteps = 0;
    _session = null;
  }

  void _enqueue(Future<void> Function() operation) {
    _operationQueue = _operationQueue.then((_) => operation()).catchError((
      Object error,
    ) {
      debugPrint('Step sensor event failed: $error');
    });
  }

  Future<void> _handleNativeEvent(NativeMotionEvent nativeEvent) async {
    switch (nativeEvent) {
      case NativeTrackingStatusEvent():
        _backgroundRunning = nativeEvent.running;
        if (nativeEvent.userId == null || nativeEvent.userId == _activeUserId) {
          _dailyTotalSteps = nativeEvent.acceptedTotal;
          _session = _session?.copyWith(
            nextSequence: nativeEvent.nextSequence,
            attested: nativeEvent.attested,
          );
          onStepsChanged?.call(_dailyTotalSteps);
          await _saveCurrentState();
        }
      case NativeStepEvent():
      case NativeMotionWindowEvent():
      // Raw native events are owned and persisted by BackgroundStepService.
    }
  }

  Future<void> _ensureSession() async {
    if (_activeUserId == null || _session?.isExpired == false) return;
    try {
      final capabilities = await _androidBridge.getCapabilities();
      if (!capabilities.accelerometerAvailable ||
          (!capabilities.stepDetectorAvailable &&
              !capabilities.stepCounterAvailable)) {
        throw StateError('Required Android motion sensors are unavailable.');
      }
      _session = await _repository.createSession(capabilities.preferredMode);
      await _saveCurrentState();
    } on DioException catch (error) {
      debugPrint(
        'Step session request failed with HTTP ${error.response?.statusCode}.',
      );
    } catch (error) {
      debugPrint('Step session request failed: $error');
    }
  }

  Future<void> _resetForDate(String stepDate) async {
    _stepDate = stepDate;
    _dailyTotalSteps = 0;
    await _saveCurrentState();
  }

  Future<void> _saveCurrentState() async {
    final userId = _activeUserId;
    final stepDate = _stepDate;
    if (userId == null || stepDate == null) return;
    await _store.saveState(
      userId,
      StoredDailyStepState(
        stepDate: stepDate,
        dailyTotalSteps: _dailyTotalSteps,
        session: _session,
        pendingEvents: const [],
        pendingWindows: const [],
      ),
    );
  }

  String _formatVietnamDate(DateTime value) {
    final vietnamTime = value.toUtc().add(_vietnamUtcOffset);
    final year = vietnamTime.year.toString().padLeft(4, '0');
    final month = vietnamTime.month.toString().padLeft(2, '0');
    final day = vietnamTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _cancelSensorSubscription() async {
    await _motionSubscription?.cancel();
    _motionSubscription = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(resumeTracking());
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cancelSensorSubscription());
  }
}
