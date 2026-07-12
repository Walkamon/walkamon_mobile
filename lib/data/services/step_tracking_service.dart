import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/widgets.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../repositories/daily_step_repository.dart';
import 'step_tracking_store.dart';

typedef StepCountStreamFactory = Stream<int> Function();
typedef ActivityPermissionChecker = Future<bool> Function();
typedef CurrentTimeProvider = DateTime Function();
typedef StepDeltaSyncer = Future<bool> Function(int stepCount);

class StepTrackingService extends WidgetsBindingObserver {
  StepTrackingService({
    StepTrackingStore? store,
    StepDeltaSyncer? stepDeltaSyncer,
    StepCountStreamFactory? stepCountStreamFactory,
    ActivityPermissionChecker? activityPermissionChecker,
    CurrentTimeProvider? currentTimeProvider,
    this.syncInterval = const Duration(minutes: 1),
  }) : _store = store ?? StepTrackingStore(),
       _stepDeltaSyncer =
           stepDeltaSyncer ?? DailyStepRepository().syncStepDelta,
       _stepCountStreamFactory =
           stepCountStreamFactory ??
           (() => Pedometer.stepCountStream.map((event) => event.steps)),
       _activityPermissionChecker =
           activityPermissionChecker ??
           (() => Permission.activityRecognition.isGranted),
       _currentTimeProvider = currentTimeProvider ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
  }

  static const _vietnamUtcOffset = Duration(hours: 7);

  final StepTrackingStore _store;
  final StepDeltaSyncer _stepDeltaSyncer;
  final StepCountStreamFactory _stepCountStreamFactory;
  final ActivityPermissionChecker _activityPermissionChecker;
  final CurrentTimeProvider _currentTimeProvider;
  final Duration syncInterval;

  StreamSubscription<int>? _stepSubscription;
  Timer? _syncTimer;
  Future<void> _operationQueue = Future<void>.value();

  String? _activeUserId;
  String? _stepDate;
  int _dailyTotalSteps = 0;
  int _pendingDeltaSteps = 0;
  int? _lastSensorCount;
  bool _isForeground = true;
  bool _disposed = false;

  ValueChanged<int>? onStepsChanged;

  int get currentStepCount => _dailyTotalSteps;
  int get pendingDeltaSteps => _pendingDeltaSteps;
  String? get activeUserId => _activeUserId;
  bool get isTracking => _stepSubscription != null;

  Future<void> startForUser(String userId) async {
    if (kIsWeb) {
      // debugPrint("======> Chạy trên Web: Bỏ qua toàn bộ logic đếm bước chân.");
      return;
    }

    if (_disposed || userId.isEmpty) return;
    if (_activeUserId == userId) {
      await resumeTracking();
      return;
    }

    try {
      await stopForUser();
      _activeUserId = userId;

      final today = _formatVietnamDate(_currentTimeProvider());
      final storedState = await _store.loadState(userId);
      if (storedState != null && storedState.stepDate == today) {
        _stepDate = storedState.stepDate;
        _dailyTotalSteps = storedState.dailyTotalSteps;
        _pendingDeltaSteps = storedState.pendingDeltaSteps;
        _lastSensorCount = storedState.lastSensorCount;
      } else {
        await _resetForDate(today);
      }

      onStepsChanged?.call(_dailyTotalSteps);
      if (_isForeground) await resumeTracking();
    } catch (e) {}
  }

  Future<void> resumeTracking() async {
    if (kIsWeb) return;

    _isForeground = true;
    if (_disposed || _activeUserId == null) return;

    await flushPendingDelta();
    if (_stepSubscription != null) return;

    final permissionGranted = await _activityPermissionChecker();
    if (!permissionGranted || _disposed || !_isForeground) return;

    _stepSubscription = _stepCountStreamFactory().listen(
      _enqueueSensorCount,
      onError: (_) {
        unawaited(pauseTracking());
      },
    );
    _syncTimer = Timer.periodic(syncInterval, (_) {
      unawaited(flushPendingDelta());
    });
  }

  Future<void> pauseTracking() async {
    if (kIsWeb) return;

    _isForeground = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    await _stepSubscription?.cancel();
    _stepSubscription = null;
    await _operationQueue;
    await flushPendingDelta();
  }

  Future<void> stopForUser() async {
    if (kIsWeb) return;

    _syncTimer?.cancel();
    _syncTimer = null;
    await _stepSubscription?.cancel();
    _stepSubscription = null;
    await _operationQueue;
    await flushPendingDelta();

    _activeUserId = null;
    _stepDate = null;
    _dailyTotalSteps = 0;
    _pendingDeltaSteps = 0;
    _lastSensorCount = null;
  }

  Future<void> flushPendingDelta() {
    final completer = Completer<void>();
    _operationQueue = _operationQueue
        .then((_) => _syncPendingDeltaInternal())
        .then(completer.complete)
        .catchError(completer.completeError);
    return completer.future;
  }

  void _enqueueSensorCount(int sensorCount) {
    _operationQueue = _operationQueue
        .then((_) => _handleSensorCount(sensorCount))
        .catchError((_) {
          // Keep the stream processing queue alive after a storage failure.
        });
  }

  Future<void> _handleSensorCount(int sensorCount) async {
    final userId = _activeUserId;
    if (userId == null || sensorCount < 0) return;

    final today = _formatVietnamDate(_currentTimeProvider());
    if (_stepDate != today) {
      await _resetForDate(today, lastSensorCount: sensorCount);
      onStepsChanged?.call(_dailyTotalSteps);
      return;
    }

    final previousSensorCount = _lastSensorCount;
    _lastSensorCount = sensorCount;
    if (previousSensorCount == null) {
      await _saveCurrentState();
      return;
    }

    final delta = sensorCount >= previousSensorCount
        ? sensorCount - previousSensorCount
        : sensorCount;
    if (delta <= 0) {
      await _saveCurrentState();
      return;
    }

    _dailyTotalSteps += delta;
    _pendingDeltaSteps += delta;
    await _saveCurrentState();
    onStepsChanged?.call(_dailyTotalSteps);
  }

  Future<void> _syncPendingDeltaInternal() async {
    final today = _formatVietnamDate(_currentTimeProvider());
    if (_stepDate != null && _stepDate != today) {
      await _resetForDate(today);
      onStepsChanged?.call(_dailyTotalSteps);
      return;
    }

    final userId = _activeUserId;
    if (userId == null || _pendingDeltaSteps <= 0) return;

    final deltaToSync = _pendingDeltaSteps;
    final synced = await _stepDeltaSyncer(deltaToSync);
    if (!synced) return;

    _pendingDeltaSteps = _pendingDeltaSteps > deltaToSync
        ? _pendingDeltaSteps - deltaToSync
        : 0;
    await _saveCurrentState();
  }

  Future<void> _resetForDate(String stepDate, {int? lastSensorCount}) async {
    _stepDate = stepDate;
    _dailyTotalSteps = 0;
    _pendingDeltaSteps = 0;
    _lastSensorCount = lastSensorCount;
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
        pendingDeltaSteps: _pendingDeltaSteps,
        lastSensorCount: _lastSensorCount,
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(resumeTracking());
    } else {
      unawaited(pauseTracking());
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    unawaited(_stepSubscription?.cancel());
    _stepSubscription = null;
  }
}
