import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/data/models/step_sensor_models.dart';

void main() {
  test('parses native background tracking status', () {
    final event = NativeMotionEvent.fromJson(const {
      'eventType': 'tracking_status',
      'running': true,
      'userId': 'user-1',
      'acceptedTotal': 321,
      'pendingSteps': 4,
      'localPendingSteps': 1,
      'serverPendingSteps': 3,
      'lastRejectedSteps': 2,
      'nextSequence': 7,
      'attested': true,
      'message': 'tracking',
      'sessionId': 'native-session',
      'nonce': 'native-nonce',
      'expiresAtMs': 1760000000000,
      'contractVersion': 3,
      'captureMode': 'dual',
    });

    expect(event, isA<NativeTrackingStatusEvent>());
    final status = event as NativeTrackingStatusEvent;
    expect(status.running, isTrue);
    expect(status.userId, 'user-1');
    expect(status.acceptedTotal, 321);
    expect(status.pendingSteps, 4);
    expect(status.localPendingSteps, 1);
    expect(status.serverPendingSteps, 3);
    expect(status.lastRejectedSteps, 2);
    expect(status.sessionId, 'native-session');
    expect(status.contractVersion, 3);
    expect(status.captureMode, 'dual');
    expect(status.nextSequence, 7);
    expect(status.attested, isTrue);
  });

  test('canonical hash matches the backend contract', () {
    final session = StepSensorSession(
      id: '11111111-2222-3333-4444-555555555555',
      nonce: 'NONCE',
      mode: StepSensorMode.counter,
      expiresAt: DateTime.utc(2026, 7, 18),
      nextSequence: 1,
    );
    final events = [
      StepSensorEvent(
        intervalStartedAt: DateTime.parse('2026-07-17T03:00:01.000Z'),
        recordedAt: DateTime.parse('2026-07-17T03:00:02.000Z'),
        stepCount: 2,
        sensorStartTotal: 1200,
        sensorEndTotal: 1202,
      ),
      StepSensorEvent(
        intervalStartedAt: DateTime.parse('2026-07-17T03:00:02.000Z'),
        recordedAt: DateTime.parse('2026-07-17T03:00:03.000Z'),
        stepCount: 1,
      ),
    ];
    final motionWindows = [
      StepMotionWindow(
        windowStartedAt: DateTime.parse('2026-07-17T03:00:01.000Z'),
        windowEndedAt: DateTime.parse('2026-07-17T03:00:02.000Z'),
        sampleCount: 25,
        accelerometerSource: 'linear',
        gyroscopeAvailable: true,
        activityAvailable: true,
        accelerationRmsMilli: 2310,
        accelerationPeakMilli: 8420,
        jerkRmsMilli: 12700,
        gyroscopeRmsMilli: 740,
        gyroscopePeakMilli: 3180,
        orientationDeltaMilliDegrees: 24500,
        dominantFrequencyMilliHz: 1820,
        periodicityBps: 7800,
        gaitCycleCount: 2,
        activityCode: 'walking',
        activityConfidence: 78,
      ),
    ];

    expect(
      StepSensorCanonicalizer.hash(
        session: session,
        events: events,
        motionWindows: motionWindows,
      ),
      '3A1F6B8310F18DEA996E098952443ABA6A219CF7BA41C96C498167A4D39DECD2',
    );
  });

  test('stored session keeps mode and next sequence', () {
    final source = StepSensorSession(
      id: 'session',
      nonce: 'nonce',
      mode: StepSensorMode.detector,
      expiresAt: DateTime.utc(2026, 7, 18),
      nextSequence: 9,
      attested: true,
    );

    final restored = StepSensorSession.fromStoredJson(source.toStoredJson());

    expect(restored.mode, StepSensorMode.detector);
    expect(restored.nextSequence, 9);
    expect(restored.attested, isTrue);
    expect(restored.expiresAt, source.expiresAt);
  });

  test('stored v3 session keeps the negotiated dual capture mode', () {
    final source = StepSensorSession(
      id: 'session-v3',
      nonce: 'nonce',
      mode: StepSensorMode.detector,
      expiresAt: DateTime.utc(2026, 8, 10),
      nextSequence: 3,
      contractVersion: 3,
      negotiatedCaptureMode: StepCaptureMode.dual,
    );

    final restored = StepSensorSession.fromStoredJson(source.toStoredJson());

    expect(restored.contractVersion, 3);
    expect(restored.captureMode, StepCaptureMode.dual);
  });

  test('parses authoritative daily step totals from backend', () {
    final session = StepSensorSession.fromJson(const {
      'stepSessionId': 'session',
      'nonce': 'nonce',
      'expiresAt': '2026-07-18T00:00:00Z',
      'nextSequence': 4,
      'dailyStepDate': '2026-07-17',
      'dailyAcceptedTotal': 4321,
    }, StepSensorMode.counter);
    final batch = StepSensorBatchResult.fromJson(const {
      'acceptedSteps': 3,
      'rejectedSteps': 0,
      'suspiciousSteps': 0,
      'nextSequence': 5,
      'dailyStepDate': '2026-07-17',
      'dailyAcceptedTotal': 4324,
    });

    expect(session.dailyStepDate, '2026-07-17');
    expect(session.dailyAcceptedTotal, 4321);
    expect(batch.dailyStepDate, '2026-07-17');
    expect(batch.dailyAcceptedTotal, 4324);
  });
}
