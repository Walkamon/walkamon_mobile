import '../datasources/remote/daily_step_datasource.dart';
import '../models/step_sensor_models.dart';

class DailyStepRepository {
  DailyStepRepository({DailyStepDatasource? datasource})
    : _datasource = datasource ?? DailyStepDatasource();

  final DailyStepDatasource _datasource;

  Future<StepSensorSession> createSession(
    StepSensorMode mode, {
    int contractVersion = 2,
    StepCaptureMode? captureMode,
  }) => _datasource.createSession(
    mode,
    contractVersion: contractVersion,
    captureMode: captureMode,
  );

  Future<StepSensorBatchResult> submitBatch({
    required StepSensorSession session,
    required String payloadHash,
    required String attestationToken,
    required List<StepSensorEvent> events,
    required List<StepMotionWindow> motionWindows,
  }) => _datasource.submitBatch(
    session: session,
    payloadHash: payloadHash,
    attestationToken: attestationToken,
    events: events,
    motionWindows: motionWindows,
  );
}
