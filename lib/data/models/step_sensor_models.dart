import 'dart:convert';

import 'package:crypto/crypto.dart';

enum StepSensorMode {
  detector,
  counter;

  String get code => name;
}

enum StepCaptureMode {
  dual('dual'),
  detectorOnly('detector_only'),
  counterOnly('counter_only');

  const StepCaptureMode(this.code);
  final String code;

  StepSensorMode get legacyMode => switch (this) {
    StepCaptureMode.counterOnly => StepSensorMode.counter,
    _ => StepSensorMode.detector,
  };

  static StepCaptureMode fromCode(String? code, StepSensorMode fallback) =>
      StepCaptureMode.values.firstWhere(
        (value) => value.code == code,
        orElse: () => fallback == StepSensorMode.detector
            ? StepCaptureMode.detectorOnly
            : StepCaptureMode.counterOnly,
      );
}

class StepMotionPolicy {
  const StepMotionPolicy({
    this.contractVersion = 2,
    this.required = true,
    this.windowMilliseconds = 1000,
    this.targetSampleHz = 25,
    this.minSamplesPerWindow = 15,
    this.maxSamplesPerWindow = 40,
  });

  final int contractVersion;
  final bool required;
  final int windowMilliseconds;
  final int targetSampleHz;
  final int minSamplesPerWindow;
  final int maxSamplesPerWindow;

  factory StepMotionPolicy.fromJson(Map<String, dynamic>? json) =>
      StepMotionPolicy(
        contractVersion: _asInt(json?['contractVersion'], 2),
        required: json?['required'] != false,
        windowMilliseconds: _asInt(json?['windowMilliseconds'], 1000),
        targetSampleHz: _asInt(json?['targetSampleHz'], 25),
        minSamplesPerWindow: _asInt(json?['minSamplesPerWindow'], 15),
        maxSamplesPerWindow: _asInt(json?['maxSamplesPerWindow'], 40),
      );

  Map<String, dynamic> toJson() => {
    'contractVersion': contractVersion,
    'required': required,
    'windowMilliseconds': windowMilliseconds,
    'targetSampleHz': targetSampleHz,
    'minSamplesPerWindow': minSamplesPerWindow,
    'maxSamplesPerWindow': maxSamplesPerWindow,
  };
}

class StepSensorSession {
  const StepSensorSession({
    required this.id,
    required this.nonce,
    required this.mode,
    required this.expiresAt,
    required this.nextSequence,
    this.attested = false,
    this.contractVersion = 2,
    this.negotiatedCaptureMode,
    this.motionPolicy = const StepMotionPolicy(),
    this.dailyStepDate,
    this.dailyAcceptedTotal,
  });

  final String id;
  final String nonce;
  final StepSensorMode mode;
  final DateTime expiresAt;
  final int nextSequence;
  final bool attested;
  final int contractVersion;
  final StepCaptureMode? negotiatedCaptureMode;
  final StepMotionPolicy motionPolicy;
  final String? dailyStepDate;
  final int? dailyAcceptedTotal;

  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());
  StepCaptureMode get captureMode =>
      negotiatedCaptureMode ??
      (mode == StepSensorMode.detector
          ? StepCaptureMode.detectorOnly
          : StepCaptureMode.counterOnly);

  StepSensorSession copyWith({int? nextSequence, bool? attested}) =>
      StepSensorSession(
        id: id,
        nonce: nonce,
        mode: mode,
        expiresAt: expiresAt,
        nextSequence: nextSequence ?? this.nextSequence,
        attested: attested ?? this.attested,
        contractVersion: contractVersion,
        negotiatedCaptureMode: negotiatedCaptureMode,
        motionPolicy: motionPolicy,
        dailyStepDate: dailyStepDate,
        dailyAcceptedTotal: dailyAcceptedTotal,
      );

  factory StepSensorSession.fromJson(
    Map<String, dynamic> json,
    StepSensorMode mode,
  ) => StepSensorSession(
    id: json['stepSessionId']?.toString() ?? '',
    nonce: json['nonce']?.toString() ?? '',
    mode: mode,
    expiresAt:
        DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    nextSequence: _asInt(json['nextSequence'], 1),
    attested: false,
    contractVersion: _asInt(json['contractVersion'], 2),
    negotiatedCaptureMode: StepCaptureMode.fromCode(
      json['captureMode']?.toString(),
      mode,
    ),
    dailyStepDate: json['dailyStepDate']?.toString(),
    dailyAcceptedTotal: _nullableInt(json['dailyAcceptedTotal']),
    motionPolicy: StepMotionPolicy.fromJson(
      json['motionPolicy'] is Map
          ? Map<String, dynamic>.from(json['motionPolicy'] as Map)
          : null,
    ),
  );

  factory StepSensorSession.fromStoredJson(Map<String, dynamic> json) =>
      StepSensorSession(
        id: json['id']?.toString() ?? '',
        nonce: json['nonce']?.toString() ?? '',
        mode: StepSensorMode.values.firstWhere(
          (value) => value.code == json['mode'],
          orElse: () => StepSensorMode.counter,
        ),
        expiresAt:
            DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        nextSequence: _asInt(json['nextSequence'], 1),
        attested: json['attested'] == true,
        contractVersion: _asInt(json['contractVersion'], 2),
        negotiatedCaptureMode: StepCaptureMode.fromCode(
          json['captureMode']?.toString(),
          StepSensorMode.values.firstWhere(
            (value) => value.code == json['mode'],
            orElse: () => StepSensorMode.counter,
          ),
        ),
        dailyStepDate: json['dailyStepDate']?.toString(),
        dailyAcceptedTotal: _nullableInt(json['dailyAcceptedTotal']),
        motionPolicy: StepMotionPolicy.fromJson(
          json['motionPolicy'] is Map
              ? Map<String, dynamic>.from(json['motionPolicy'] as Map)
              : null,
        ),
      );

  Map<String, dynamic> toStoredJson() => {
    'id': id,
    'nonce': nonce,
    'mode': mode.code,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'nextSequence': nextSequence,
    'attested': attested,
    'contractVersion': contractVersion,
    'captureMode': captureMode.code,
    'dailyStepDate': dailyStepDate,
    'dailyAcceptedTotal': dailyAcceptedTotal,
    'motionPolicy': motionPolicy.toJson(),
  };
}

class StepSensorEvent {
  const StepSensorEvent({
    required this.intervalStartedAt,
    required this.recordedAt,
    required this.stepCount,
    this.sensorStartTotal,
    this.sensorEndTotal,
  });

  final DateTime intervalStartedAt;
  final DateTime recordedAt;
  final int stepCount;
  final int? sensorStartTotal;
  final int? sensorEndTotal;

  Map<String, dynamic> toJson() => {
    'intervalStartedAt': intervalStartedAt.toUtc().toIso8601String(),
    'recordedAt': recordedAt.toUtc().toIso8601String(),
    'stepCount': stepCount,
    'sensorStartTotal': sensorStartTotal,
    'sensorEndTotal': sensorEndTotal,
  };

  factory StepSensorEvent.fromJson(Map<String, dynamic> json) =>
      StepSensorEvent(
        intervalStartedAt:
            DateTime.tryParse(
              json['intervalStartedAt']?.toString() ?? '',
            )?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        recordedAt:
            DateTime.tryParse(json['recordedAt']?.toString() ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        stepCount: _asInt(json['stepCount']),
        sensorStartTotal: _nullableInt(json['sensorStartTotal']),
        sensorEndTotal: _nullableInt(json['sensorEndTotal']),
      );
}

class StepMotionWindow {
  const StepMotionWindow({
    required this.windowStartedAt,
    required this.windowEndedAt,
    required this.sampleCount,
    required this.accelerometerSource,
    required this.gyroscopeAvailable,
    required this.activityAvailable,
    required this.accelerationRmsMilli,
    required this.accelerationPeakMilli,
    required this.jerkRmsMilli,
    required this.gyroscopeRmsMilli,
    required this.gyroscopePeakMilli,
    required this.orientationDeltaMilliDegrees,
    required this.dominantFrequencyMilliHz,
    required this.periodicityBps,
    required this.gaitCycleCount,
    required this.activityCode,
    required this.activityConfidence,
  });

  final DateTime windowStartedAt;
  final DateTime windowEndedAt;
  final int sampleCount;
  final String accelerometerSource;
  final bool gyroscopeAvailable;
  final bool activityAvailable;
  final int accelerationRmsMilli;
  final int accelerationPeakMilli;
  final int jerkRmsMilli;
  final int? gyroscopeRmsMilli;
  final int? gyroscopePeakMilli;
  final int? orientationDeltaMilliDegrees;
  final int dominantFrequencyMilliHz;
  final int periodicityBps;
  final int gaitCycleCount;
  final String activityCode;
  final int activityConfidence;

  bool overlaps(DateTime start, DateTime end) =>
      windowEndedAt.isAfter(start) &&
      (windowStartedAt.isBefore(end) || windowStartedAt.isAtSameMomentAs(end));

  Map<String, dynamic> toJson() => {
    'windowStartedAt': windowStartedAt.toUtc().toIso8601String(),
    'windowEndedAt': windowEndedAt.toUtc().toIso8601String(),
    'sampleCount': sampleCount,
    'accelerometerSource': accelerometerSource,
    'gyroscopeAvailable': gyroscopeAvailable,
    'activityAvailable': activityAvailable,
    'accelerationRmsMilli': accelerationRmsMilli,
    'accelerationPeakMilli': accelerationPeakMilli,
    'jerkRmsMilli': jerkRmsMilli,
    'gyroscopeRmsMilli': gyroscopeRmsMilli,
    'gyroscopePeakMilli': gyroscopePeakMilli,
    'orientationDeltaMilliDegrees': orientationDeltaMilliDegrees,
    'dominantFrequencyMilliHz': dominantFrequencyMilliHz,
    'periodicityBps': periodicityBps,
    'gaitCycleCount': gaitCycleCount,
    'activityCode': activityCode,
    'activityConfidence': activityConfidence,
  };

  factory StepMotionWindow.fromJson(
    Map<String, dynamic> json,
  ) => StepMotionWindow(
    windowStartedAt:
        DateTime.tryParse(json['windowStartedAt']?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    windowEndedAt:
        DateTime.tryParse(json['windowEndedAt']?.toString() ?? '')?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    sampleCount: _asInt(json['sampleCount']),
    accelerometerSource:
        json['accelerometerSource']?.toString() ?? 'raw_high_pass',
    gyroscopeAvailable: json['gyroscopeAvailable'] == true,
    activityAvailable: json['activityAvailable'] == true,
    accelerationRmsMilli: _asInt(json['accelerationRmsMilli']),
    accelerationPeakMilli: _asInt(json['accelerationPeakMilli']),
    jerkRmsMilli: _asInt(json['jerkRmsMilli']),
    gyroscopeRmsMilli: _nullableInt(json['gyroscopeRmsMilli']),
    gyroscopePeakMilli: _nullableInt(json['gyroscopePeakMilli']),
    orientationDeltaMilliDegrees: _nullableInt(
      json['orientationDeltaMilliDegrees'],
    ),
    dominantFrequencyMilliHz: _asInt(json['dominantFrequencyMilliHz']),
    periodicityBps: _asInt(json['periodicityBps']),
    gaitCycleCount: _asInt(json['gaitCycleCount']),
    activityCode: json['activityCode']?.toString() ?? 'unknown',
    activityConfidence: _asInt(json['activityConfidence']),
  );
}

sealed class NativeMotionEvent {
  const NativeMotionEvent();

  factory NativeMotionEvent.fromJson(Map<String, dynamic> json) {
    if (json['eventType'] == 'tracking_status') {
      return NativeTrackingStatusEvent(
        running: json['running'] == true,
        userId: json['userId']?.toString(),
        acceptedTotal: _asInt(json['acceptedTotal']),
        pendingSteps: _asInt(json['pendingSteps']),
        localPendingSteps: _asInt(json['localPendingSteps']),
        serverPendingSteps: _asInt(json['serverPendingSteps']),
        lastRejectedSteps: _asInt(json['lastRejectedSteps']),
        nextSequence: _asInt(json['nextSequence'], 1),
        attested: json['attested'] == true,
        message: json['message']?.toString(),
        sessionId: json['sessionId']?.toString(),
        nonce: json['nonce']?.toString(),
        expiresAtMs: _asInt(json['expiresAtMs']),
        stepDate: json['stepDate']?.toString(),
        contractVersion: _asInt(json['contractVersion'], 2),
        captureMode: json['captureMode']?.toString(),
      );
    }
    if (json['eventType'] == 'motion') {
      return NativeMotionWindowEvent(StepMotionWindow.fromJson(json));
    }
    return NativeStepEvent(StepSensorEvent.fromJson(json));
  }
}

final class NativeStepEvent extends NativeMotionEvent {
  const NativeStepEvent(this.event);
  final StepSensorEvent event;
}

final class NativeMotionWindowEvent extends NativeMotionEvent {
  const NativeMotionWindowEvent(this.window);
  final StepMotionWindow window;
}

final class NativeTrackingStatusEvent extends NativeMotionEvent {
  const NativeTrackingStatusEvent({
    required this.running,
    required this.userId,
    required this.acceptedTotal,
    this.pendingSteps = 0,
    this.localPendingSteps = 0,
    this.serverPendingSteps = 0,
    this.lastRejectedSteps = 0,
    required this.nextSequence,
    required this.attested,
    required this.message,
    this.sessionId,
    this.nonce,
    this.expiresAtMs = 0,
    this.stepDate,
    this.contractVersion = 2,
    this.captureMode,
  });

  final bool running;
  final String? userId;
  final int acceptedTotal;
  final int pendingSteps;
  final int localPendingSteps;
  final int serverPendingSteps;
  final int lastRejectedSteps;
  final int nextSequence;
  final bool attested;
  final String? message;
  final String? sessionId;
  final String? nonce;
  final int expiresAtMs;
  final String? stepDate;
  final int contractVersion;
  final String? captureMode;
}

class NativeTrackingStatus {
  const NativeTrackingStatus({
    required this.running,
    required this.userId,
    required this.acceptedTotal,
    this.pendingSteps = 0,
    this.localPendingSteps = 0,
    this.serverPendingSteps = 0,
    this.lastRejectedSteps = 0,
    required this.nextSequence,
    required this.attested,
    this.sessionId,
    this.nonce,
    this.expiresAtMs = 0,
    this.stepDate,
    this.contractVersion = 2,
    this.captureMode,
  });

  final bool running;
  final String? userId;
  final int acceptedTotal;
  final int pendingSteps;
  final int localPendingSteps;
  final int serverPendingSteps;
  final int lastRejectedSteps;
  final int nextSequence;
  final bool attested;
  final String? sessionId;
  final String? nonce;
  final int expiresAtMs;
  final String? stepDate;
  final int contractVersion;
  final String? captureMode;

  factory NativeTrackingStatus.fromJson(Map<String, dynamic> json) =>
      NativeTrackingStatus(
        running: json['running'] == true,
        userId: json['userId']?.toString(),
        acceptedTotal: _asInt(json['acceptedTotal']),
        pendingSteps: _asInt(json['pendingSteps']),
        localPendingSteps: _asInt(json['localPendingSteps']),
        serverPendingSteps: _asInt(json['serverPendingSteps']),
        lastRejectedSteps: _asInt(json['lastRejectedSteps']),
        nextSequence: _asInt(json['nextSequence'], 1),
        attested: json['attested'] == true,
        sessionId: json['sessionId']?.toString(),
        nonce: json['nonce']?.toString(),
        expiresAtMs: _asInt(json['expiresAtMs']),
        stepDate: json['stepDate']?.toString(),
        contractVersion: _asInt(json['contractVersion'], 2),
        captureMode: json['captureMode']?.toString(),
      );
}

class NativeSensorCapabilities {
  const NativeSensorCapabilities({
    required this.stepDetectorAvailable,
    required this.stepCounterAvailable,
    required this.accelerometerAvailable,
    required this.gyroscopeAvailable,
    required this.activityRecognitionAvailable,
  });

  final bool stepDetectorAvailable;
  final bool stepCounterAvailable;
  final bool accelerometerAvailable;
  final bool gyroscopeAvailable;
  final bool activityRecognitionAvailable;

  StepSensorMode get preferredMode =>
      stepDetectorAvailable ? StepSensorMode.detector : StepSensorMode.counter;

  StepCaptureMode get preferredCaptureMode {
    if (stepDetectorAvailable && stepCounterAvailable) {
      return StepCaptureMode.dual;
    }
    return stepDetectorAvailable
        ? StepCaptureMode.detectorOnly
        : StepCaptureMode.counterOnly;
  }

  factory NativeSensorCapabilities.fromJson(Map<String, dynamic> json) =>
      NativeSensorCapabilities(
        stepDetectorAvailable: json['stepDetectorAvailable'] == true,
        stepCounterAvailable: json['stepCounterAvailable'] == true,
        accelerometerAvailable:
            json['linearAccelerationAvailable'] == true ||
            json['accelerometerAvailable'] == true,
        gyroscopeAvailable: json['gyroscopeAvailable'] == true,
        activityRecognitionAvailable:
            json['activityRecognitionAvailable'] == true,
      );
}

class StepSensorBatchResult {
  const StepSensorBatchResult({
    required this.acceptedSteps,
    this.pendingSteps = 0,
    required this.rejectedSteps,
    required this.suspiciousSteps,
    required this.nextSequence,
    required this.attestationStatus,
    required this.motionStatus,
    required this.motionScore,
    required this.degradedEvidence,
    required this.motionReasons,
    required this.dailyStepDate,
    required this.dailyAcceptedTotal,
    this.reconciliationStatus = 'unavailable',
    this.reconciliationReason,
    this.detectorResolutions = const [],
  });

  final int acceptedSteps;
  final int pendingSteps;
  final int rejectedSteps;
  final int suspiciousSteps;
  final int nextSequence;
  final String attestationStatus;
  final String motionStatus;
  final int motionScore;
  final bool degradedEvidence;
  final List<String> motionReasons;
  final String? dailyStepDate;
  final int? dailyAcceptedTotal;
  final String reconciliationStatus;
  final String? reconciliationReason;
  final List<StepDetectorResolution> detectorResolutions;

  factory StepSensorBatchResult.fromJson(
    Map<String, dynamic> json,
  ) => StepSensorBatchResult(
    acceptedSteps: _asInt(json['acceptedSteps']),
    pendingSteps: _asInt(json['pendingSteps']),
    rejectedSteps: _asInt(json['rejectedSteps']),
    suspiciousSteps: _asInt(json['suspiciousSteps']),
    nextSequence: _asInt(json['nextSequence'], 1),
    attestationStatus: json['attestationStatus']?.toString() ?? 'unavailable',
    motionStatus: json['motionStatus']?.toString() ?? 'unavailable',
    motionScore: _asInt(json['motionScore']),
    degradedEvidence: json['degradedEvidence'] == true,
    motionReasons:
        (json['motionReasons'] as List?)
            ?.map((value) => value.toString())
            .toList() ??
        const [],
    dailyStepDate: json['dailyStepDate']?.toString(),
    dailyAcceptedTotal: _nullableInt(json['dailyAcceptedTotal']),
    reconciliationStatus:
        json['reconciliationStatus']?.toString() ?? 'unavailable',
    reconciliationReason: json['reconciliationReason']?.toString(),
    detectorResolutions:
        (json['detectorResolutions'] as List?)
            ?.whereType<Map>()
            .map(
              (value) => StepDetectorResolution.fromJson(
                Map<String, dynamic>.from(value),
              ),
            )
            .toList() ??
        const [],
  );
}

class StepDetectorResolution {
  const StepDetectorResolution({
    required this.clientEventId,
    required this.status,
    required this.acceptedStepCount,
    this.reason,
  });

  final String clientEventId;
  final String status;
  final int acceptedStepCount;
  final String? reason;

  factory StepDetectorResolution.fromJson(Map<String, dynamic> json) =>
      StepDetectorResolution(
        clientEventId: json['clientEventId']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        acceptedStepCount: _asInt(json['acceptedStepCount']),
        reason: json['reason']?.toString(),
      );
}

class StepSensorCanonicalizer {
  static String hash({
    required StepSensorSession session,
    required List<StepSensorEvent> events,
    required List<StepMotionWindow> motionWindows,
  }) {
    final lines = <String>[
      'V2',
      session.id.toLowerCase(),
      session.nextSequence.toString(),
      session.nonce,
      session.mode.code,
      ...events.map(
        (event) =>
            'E:${event.intervalStartedAt.toUtc().millisecondsSinceEpoch}:'
            '${event.recordedAt.toUtc().millisecondsSinceEpoch}:'
            '${event.stepCount}:${event.sensorStartTotal ?? ''}:'
            '${event.sensorEndTotal ?? ''}',
      ),
      ...motionWindows.map(
        (window) =>
            'M:${window.windowStartedAt.toUtc().millisecondsSinceEpoch}:'
            '${window.windowEndedAt.toUtc().millisecondsSinceEpoch}:'
            '${window.sampleCount}:${window.accelerometerSource}:'
            '${window.gyroscopeAvailable ? 1 : 0}:'
            '${window.activityAvailable ? 1 : 0}:'
            '${window.accelerationRmsMilli}:${window.accelerationPeakMilli}:'
            '${window.jerkRmsMilli}:${window.gyroscopeRmsMilli ?? ''}:'
            '${window.gyroscopePeakMilli ?? ''}:'
            '${window.orientationDeltaMilliDegrees ?? ''}:'
            '${window.dominantFrequencyMilliHz}:${window.periodicityBps}:'
            '${window.gaitCycleCount}:${window.activityCode}:'
            '${window.activityConfidence}',
      ),
    ];
    return sha256
        .convert(utf8.encode(lines.join('\n')))
        .toString()
        .toUpperCase();
  }
}

int _asInt(Object? value, [int fallback = 0]) =>
    int.tryParse(value?.toString() ?? '') ?? fallback;

int? _nullableInt(Object? value) =>
    value == null ? null : int.tryParse(value.toString());
