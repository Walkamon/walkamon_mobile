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

enum StepTrackingStatus {
  idle,
  starting,
  tracking,
  permissionDenied,
  permissionPermanentlyDenied,
  sensorUnavailable,
  authenticationRequired,
  error,
  stopped,
}

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
  Timer? _statusSyncTimer;
  Future<void> _operationQueue = Future<void>.value();

  String? _activeUserId;
  String? _stepDate;
  int _dailyTotalSteps = 0;
  StepSensorSession? _session;
  bool _backgroundRunning = false;
  bool _disposed = false;
  StepTrackingStatus _status = StepTrackingStatus.idle;

  ValueChanged<int>? onStepsChanged;
  ValueChanged<StepTrackingStatus>? onStatusChanged;

  int get currentStepCount => _dailyTotalSteps;
  String? get activeUserId => _activeUserId;
  bool get isTracking => _backgroundRunning;
  StepTrackingStatus get status => _status;

  Future<void> startForUser(String userId) async {
    if (kIsWeb || _disposed || userId.isEmpty) return;
    _setStatus(StepTrackingStatus.starting);
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
        if (_session?.dailyStepDate == today &&
            _session?.dailyAcceptedTotal != null) {
          _dailyTotalSteps = _session!.dailyAcceptedTotal!;
        }
      } else {
        await _resetForDate(today);
      }

      onStepsChanged?.call(_dailyTotalSteps);
      await resumeTracking();
    } catch (error) {
      debugPrint('Step tracking start failed: $error');
      _setStatus(StepTrackingStatus.error);
    }
  }

  Future<void> resumeTracking() async {
    if (kIsWeb) return;
    if (_disposed || _activeUserId == null) return;
    if (!await _activityPermissionChecker()) {
      _setStatus(StepTrackingStatus.permissionDenied);
      return;
    }

    await _operationQueue;
    _motionSubscription ??= _motionStreamFactory().listen(
      (event) => _enqueue(() => _handleNativeEvent(event)),
      onError: (Object error) {
        debugPrint('Background step status stream failed: $error');
      },
    );

    final nativeStatus = await _androidBridge.getTrackingStatus();
    if (nativeStatus.running && nativeStatus.userId == _activeUserId) {
      await _applyNativeStatus(
        running: nativeStatus.running,
        userId: nativeStatus.userId,
        acceptedTotal: nativeStatus.acceptedTotal,
        nextSequence: nativeStatus.nextSequence,
        attested: nativeStatus.attested,
      );
      _startStatusSync();
      return;
    }

    await _ensureSession();
    final session = _session;
    if (session == null) return;
    final preferences = await SharedPreferences.getInstance();
    final accessToken = preferences.getString('access_token');
    if (accessToken == null || accessToken.isEmpty) {
      _setStatus(StepTrackingStatus.authenticationRequired);
      return;
    }

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
    _setStatus(StepTrackingStatus.tracking);
    _startStatusSync();
  }

  Future<void> requestActivityPermission() async {
    final current = await Permission.activityRecognition.status;
    if (current.isPermanentlyDenied) {
      _setStatus(StepTrackingStatus.permissionPermanentlyDenied);
      return;
    }
    final result = await Permission.activityRecognition.request();
    if (!result.isGranted) {
      _setStatus(
        result.isPermanentlyDenied
            ? StepTrackingStatus.permissionPermanentlyDenied
            : StepTrackingStatus.permissionDenied,
      );
      return;
    }
    await resumeTracking();
  }

  Future<void> openActivitySettings() => openAppSettings();

  Future<void> pauseTracking() async {
    if (kIsWeb) return;
    // The Android health foreground service intentionally keeps running.
  }

  Future<void> stopForUser() async {
    if (kIsWeb) return;
    await _androidBridge.stopCollector();
    _stopStatusSync();
    await _cancelSensorSubscription();
    await _operationQueue;

    _backgroundRunning = false;
    _activeUserId = null;
    _stepDate = null;
    _dailyTotalSteps = 0;
    _session = null;
    _setStatus(StepTrackingStatus.stopped);
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
        await _applyNativeStatus(
          running: nativeEvent.running,
          userId: nativeEvent.userId,
          acceptedTotal: nativeEvent.acceptedTotal,
          nextSequence: nativeEvent.nextSequence,
          attested: nativeEvent.attested,
        );
        if (nativeEvent.message == 'activity_permission_required') {
          _setStatus(StepTrackingStatus.permissionDenied);
        } else if (nativeEvent.message == 'authentication_required') {
          _setStatus(StepTrackingStatus.authenticationRequired);
        } else if (nativeEvent.running) {
          _setStatus(StepTrackingStatus.tracking);
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
      if (_session?.dailyStepDate == _stepDate &&
          _session?.dailyAcceptedTotal != null) {
        _dailyTotalSteps = _session!.dailyAcceptedTotal!;
        onStepsChanged?.call(_dailyTotalSteps);
      }
      await _saveCurrentState();
    } on DioException catch (error) {
      debugPrint(
        'Step session request failed with HTTP ${error.response?.statusCode}.',
      );
      _setStatus(StepTrackingStatus.error);
    } catch (error) {
      debugPrint('Step session request failed: $error');
      _setStatus(
        error is StateError
            ? StepTrackingStatus.sensorUnavailable
            : StepTrackingStatus.error,
      );
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

  Future<void> _applyNativeStatus({
    required bool running,
    required String? userId,
    required int acceptedTotal,
    required int nextSequence,
    required bool attested,
  }) async {
    if (userId != null && userId != _activeUserId) return;

    _backgroundRunning = running;
    final previousSequence = _session?.nextSequence;
    final previousAttested = _session?.attested;
    final sessionChanged =
        _session != null &&
        (previousSequence != nextSequence || previousAttested != attested);
    final changed = _dailyTotalSteps != acceptedTotal || sessionChanged;
    _dailyTotalSteps = acceptedTotal;
    _session = _session?.copyWith(
      nextSequence: nextSequence,
      attested: attested,
    );
    if (changed) {
      onStepsChanged?.call(_dailyTotalSteps);
      await _saveCurrentState();
    }
    if (running) _setStatus(StepTrackingStatus.tracking);
  }

  void _startStatusSync() {
    _statusSyncTimer ??= Timer.periodic(syncInterval, (_) {
      if (!_disposed && _activeUserId != null) {
        _enqueue(_syncNativeStatus);
      }
    });
  }

  void _stopStatusSync() {
    _statusSyncTimer?.cancel();
    _statusSyncTimer = null;
  }

  Future<void> _syncNativeStatus() async {
    try {
      final nativeStatus = await _androidBridge.getTrackingStatus();
      await _applyNativeStatus(
        running: nativeStatus.running,
        userId: nativeStatus.userId,
        acceptedTotal: nativeStatus.acceptedTotal,
        nextSequence: nativeStatus.nextSequence,
        attested: nativeStatus.attested,
      );
    } catch (error) {
      debugPrint('Background step status sync failed: $error');
    }
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
    _stopStatusSync();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cancelSensorSubscription());
  }

  void _setStatus(StepTrackingStatus status) {
    if (_status == status) return;
    _status = status;
    onStatusChanged?.call(status);
  }
}
