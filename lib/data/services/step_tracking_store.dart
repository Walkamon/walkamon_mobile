import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredDailyStepState {
  const StoredDailyStepState({
    required this.stepDate,
    required this.dailyTotalSteps,
    required this.pendingDeltaSteps,
    required this.lastSensorCount,
  });

  final String stepDate;
  final int dailyTotalSteps;
  final int pendingDeltaSteps;
  final int? lastSensorCount;
}

class StepTrackingStore {
  StepTrackingStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _stateKey(String userId) => 'step_tracking.state_v2.$userId';

  Future<StoredDailyStepState?> loadState(String userId) async {
    final preferences = await _getPrefs();
    final encoded = preferences.getString(_stateKey(userId));
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      return StoredDailyStepState(
        stepDate: json['stepDate'] as String? ?? '',
        dailyTotalSteps: json['dailyTotalSteps'] as int? ?? 0,
        pendingDeltaSteps: json['pendingDeltaSteps'] as int? ?? 0,
        lastSensorCount: json['lastSensorCount'] as int?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveState(String userId, StoredDailyStepState state) async {
    final preferences = await _getPrefs();
    await preferences.setString(
      _stateKey(userId),
      jsonEncode({
        'stepDate': state.stepDate,
        'dailyTotalSteps': state.dailyTotalSteps,
        'pendingDeltaSteps': state.pendingDeltaSteps,
        'lastSensorCount': state.lastSensorCount,
      }),
    );
  }
}
