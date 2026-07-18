import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_provider.dart';
import '../../models/step_sensor_models.dart';

class DailyStepDatasource {
  DailyStepDatasource({Dio? dio}) : _dio = dio ?? DioProvider.instance;

  final Dio _dio;

  Future<StepSensorSession> createSession(StepSensorMode mode) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.stepSensorSession,
      data: {'platformCode': 'android', 'sensorModeCode': mode.code},
    );
    return StepSensorSession.fromJson(_data(response.data), mode);
  }

  Future<StepSensorBatchResult> submitBatch({
    required StepSensorSession session,
    required String payloadHash,
    required String attestationToken,
    required List<StepSensorEvent> events,
    required List<StepMotionWindow> motionWindows,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.stepSensorBatches(session.id),
      data: {
        'contractVersion': session.motionPolicy.contractVersion,
        'sequence': session.nextSequence,
        'nonce': session.nonce,
        'payloadHash': payloadHash,
        'attestationToken': attestationToken,
        'events': events.map((event) => event.toJson()).toList(),
        'motionWindows': motionWindows
            .map((window) => window.toJson())
            .toList(),
      },
    );
    return StepSensorBatchResult.fromJson(_data(response.data));
  }

  Map<String, dynamic> _data(Map<String, dynamic>? envelope) {
    final value = envelope?['data'] ?? envelope?['Data'];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Step sensor response does not contain data.');
  }
}
