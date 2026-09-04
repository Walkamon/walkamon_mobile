import 'package:flutter/foundation.dart';

import '../data/services/step_tracking_service.dart';

class StepTrackingProvider extends ChangeNotifier {
  StepTrackingProvider({StepTrackingService? service})
    : _service = service ?? StepTrackingService() {
    _service.onStepsChanged = _onSteps;
    _service.onStepBreakdownChanged = _onStepBreakdownChanged;
    _service.onStatusChanged = _onStatusChanged;
  }

  final StepTrackingService _service;
  int _dailySteps = 0;
  int _pendingSteps = 0;
  int _localPendingSteps = 0;
  int _serverPendingSteps = 0;
  int _lastRejectedSteps = 0;
  StepTrackingStatus _status = StepTrackingStatus.idle;
  String? _desiredUserId;
  Future<void> _userSync = Future<void>.value();

  int get dailySteps => _dailySteps;
  int get pendingSteps => _pendingSteps;
  int get localPendingSteps => _localPendingSteps;
  int get serverPendingSteps => _serverPendingSteps;
  int get lastRejectedSteps => _lastRejectedSteps;
  int get displayedSteps => _dailySteps + _pendingSteps;
  bool get isTracking => _service.isTracking;
  StepTrackingStatus get status => _status;

  Future<void> startForUser(String userId) => synchronizeUser(userId);
  Future<void> stopForUser() => synchronizeUser(null);
  Future<void> resumeTracking() => _service.resumeTracking();
  Future<void> requestActivityPermission() =>
      _service.requestActivityPermission();
  Future<void> openActivitySettings() => _service.openActivitySettings();

  /// Keeps step collection aligned with the authenticated account, including
  /// cold starts where no login screen callback runs. Calls are serialized so
  /// a logout/login transition cannot leave the native collector on the
  /// previous account.
  Future<void> synchronizeUser(String? userId) {
    final normalized = userId?.trim();
    final desired = normalized == null || normalized.isEmpty
        ? null
        : normalized;
    if (_desiredUserId == desired) return _userSync;
    _desiredUserId = desired;

    _userSync = _userSync.then((_) async {
      if (_desiredUserId != desired) return;
      if (desired == null) {
        if (_service.activeUserId != null) await _service.stopForUser();
        return;
      }
      if (_service.activeUserId == desired && _service.isTracking) return;
      await _service.startForUser(desired);
    });
    return _userSync;
  }

  void _onSteps(int steps) {
    if (steps == _dailySteps) return;
    _dailySteps = steps;
    notifyListeners();
  }

  void _onStepBreakdownChanged(
    int acceptedSteps,
    int localPendingSteps,
    int serverPendingSteps,
    int lastRejectedSteps,
  ) {
    final pendingSteps = localPendingSteps + serverPendingSteps;
    if (_dailySteps == acceptedSteps &&
        _pendingSteps == pendingSteps &&
        _localPendingSteps == localPendingSteps &&
        _serverPendingSteps == serverPendingSteps &&
        _lastRejectedSteps == lastRejectedSteps) {
      return;
    }
    _dailySteps = acceptedSteps;
    _pendingSteps = pendingSteps;
    _localPendingSteps = localPendingSteps;
    _serverPendingSteps = serverPendingSteps;
    _lastRejectedSteps = lastRejectedSteps;
    notifyListeners();
  }

  void _onStatusChanged(StepTrackingStatus status) {
    if (status == _status) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
