import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/step_sensor_models.dart';

class StoredDailyStepState {
  const StoredDailyStepState({
    required this.stepDate,
    required this.dailyTotalSteps,
    required this.session,
    required this.pendingEvents,
    required this.pendingWindows,
  });

  final String stepDate;
  final int dailyTotalSteps;
  final StepSensorSession? session;
  final List<StepSensorEvent> pendingEvents;
  final List<StepMotionWindow> pendingWindows;
}

class StepTrackingStore {
  StepTrackingStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  String _stateKey(String userId) => 'step_tracking.state_v4.$userId';
  String _legacyStateKey(String userId) => 'step_tracking.state_v3.$userId';

  Future<StoredDailyStepState?> loadState(String userId) async {
    final preferences = await _getPrefs();
    final current = preferences.getString(_stateKey(userId));
    final isLegacy = current == null;
    final encoded = current ?? preferences.getString(_legacyStateKey(userId));
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final json = jsonDecode(encoded) as Map<String, dynamic>;
      final sessionJson = json['session'];
      final pendingJson = json['pendingEvents'];
      final pendingWindowsJson = json['pendingWindows'];
      return StoredDailyStepState(
        stepDate: json['stepDate']?.toString() ?? '',
        dailyTotalSteps: isLegacy
            ? 0
            : int.tryParse(json['dailyTotalSteps']?.toString() ?? '') ?? 0,
        session: sessionJson is Map
            ? StepSensorSession.fromStoredJson(
                Map<String, dynamic>.from(sessionJson),
              )
            : null,
        pendingEvents: pendingJson is List
            ? pendingJson
                  .whereType<Map>()
                  .map(
                    (event) => StepSensorEvent.fromJson(
                      Map<String, dynamic>.from(event),
                    ),
                  )
                  .toList()
            : const [],
        pendingWindows: pendingWindowsJson is List
            ? pendingWindowsJson
                  .whereType<Map>()
                  .map(
                    (window) => StepMotionWindow.fromJson(
                      Map<String, dynamic>.from(window),
                    ),
                  )
                  .toList()
            : const [],
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
        'session': state.session?.toStoredJson(),
        'pendingEvents': state.pendingEvents
            .map((event) => event.toJson())
            .toList(),
        'pendingWindows': state.pendingWindows
            .map((window) => window.toJson())
            .toList(),
      }),
    );
  }
}
