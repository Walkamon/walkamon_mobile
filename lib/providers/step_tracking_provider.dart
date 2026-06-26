import 'package:flutter/foundation.dart';

import '../data/services/step_tracking_service.dart';

class StepTrackingProvider extends ChangeNotifier {
  StepTrackingProvider({StepTrackingService? service})
    : _service = service ?? StepTrackingService() {
    _service.onStepsChanged = _onSteps;
  }

  final StepTrackingService _service;
  int _dailySteps = 0;

  int get dailySteps => _dailySteps;
  bool get isTracking => _service.isTracking;

  Future<void> startForUser(String userId) => _service.startForUser(userId);
  Future<void> stopForUser() => _service.stopForUser();
  Future<void> resumeTracking() => _service.resumeTracking();

  void _onSteps(int steps) {
    if (steps == _dailySteps) return;
    _dailySteps = steps;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
