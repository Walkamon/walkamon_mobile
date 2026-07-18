import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/step_sensor_models.dart';

class AndroidStepBridge {
  static const _channel = MethodChannel('walkamon/validated_steps');
  static const _events = EventChannel('walkamon/motion_events');
  static const _usePlayIntegrityInDebug = bool.fromEnvironment(
    'USE_PLAY_INTEGRITY_IN_DEBUG',
  );

  Future<NativeSensorCapabilities> getCapabilities() async {
    try {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'getCapabilities',
      );
      return NativeSensorCapabilities.fromJson(value ?? const {});
    } on PlatformException {
      return const NativeSensorCapabilities(
        stepDetectorAvailable: false,
        stepCounterAvailable: true,
        accelerometerAvailable: true,
        gyroscopeAvailable: false,
        activityRecognitionAvailable: false,
      );
    }
  }

  static Stream<NativeMotionEvent> motionEvents() => _events
      .receiveBroadcastStream()
      .where((value) => value is Map)
      .map(
        (value) =>
            NativeMotionEvent.fromJson(Map<String, dynamic>.from(value as Map)),
      );

  Future<void> startCollector({
    required String userId,
    required String stepDate,
    required String apiBaseUrl,
    required String accessToken,
    required StepSensorMode mode,
    required StepMotionPolicy policy,
    required StepSensorSession session,
    required int acceptedTotal,
  }) => _channel.invokeMethod<void>('startCollector', {
    'userId': userId,
    'stepDate': stepDate,
    'apiBaseUrl': apiBaseUrl,
    'accessToken': accessToken,
    'sensorMode': mode.code,
    'windowMilliseconds': policy.windowMilliseconds,
    'targetSampleHz': policy.targetSampleHz,
    'contractVersion': policy.contractVersion,
    'sessionId': session.id,
    'nonce': session.nonce,
    'expiresAtMs': session.expiresAt.millisecondsSinceEpoch,
    'nextSequence': session.nextSequence,
    'attested': session.attested,
    'allowDevelopmentBypass': kDebugMode && !_usePlayIntegrityInDebug,
    'acceptedTotal': acceptedTotal,
  });

  Future<void> stopCollector() => _channel.invokeMethod<void>('stopCollector');

  Future<NativeTrackingStatus> getTrackingStatus() async {
    final value = await _channel.invokeMapMethod<String, dynamic>(
      'getTrackingStatus',
    );
    return NativeTrackingStatus.fromJson(value ?? const {});
  }

  Future<void> prepareIntegrity() async {
    if (kDebugMode && !_usePlayIntegrityInDebug) return;
    await _channel.invokeMethod<void>('prepareIntegrity');
  }

  Future<String> attestationToken(String payloadHash) async {
    if (kDebugMode && !_usePlayIntegrityInDebug) {
      return 'DEV_BYPASS:$payloadHash';
    }
    String? token;
    try {
      token = await _requestIntegrityToken(payloadHash);
    } on PlatformException catch (error) {
      if (error.code != 'PLAY_INTEGRITY_NOT_PREPARED' &&
          error.code != 'PLAY_INTEGRITY_REQUEST_FAILED') {
        rethrow;
      }
      await prepareIntegrity();
      token = await _requestIntegrityToken(payloadHash);
    }
    if (token == null || token.isEmpty) {
      throw StateError('Play Integrity returned an empty token.');
    }
    return token;
  }

  Future<String?> _requestIntegrityToken(String payloadHash) =>
      _channel.invokeMethod<String>('requestIntegrityToken', {
        'requestHash': payloadHash,
      });
}
