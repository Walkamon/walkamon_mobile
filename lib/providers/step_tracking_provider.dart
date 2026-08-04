import 'package:flutter/foundation.dart';

import '../data/services/step_tracking_service.dart';

class StepTrackingProvider extends ChangeNotifier {
  StepTrackingProvider({StepTrackingService? service})
    : _service = service ?? StepTrackingService() {
    _service.onStepsChanged = _onSteps;
    _service.onStatusChanged = _onStatusChanged;
  }

  final StepTrackingService _service;
  int _dailySteps = 0;
  StepTrackingStatus _status = StepTrackingStatus.idle;

  int get dailySteps => _dailySteps;
  bool get isTracking => _service.isTracking;
  StepTrackingStatus get status => _status;

  Future<void> startForUser(String userId) => _service.startForUser(userId);
  Future<void> stopForUser() => _service.stopForUser();
  Future<void> resumeTracking() => _service.resumeTracking();
  Future<void> requestActivityPermission() =>
      _service.requestActivityPermission();
  Future<void> openActivitySettings() => _service.openActivitySettings();

  void _onSteps(int steps) {
    if (steps == _dailySteps) return;
    _dailySteps = steps;
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
