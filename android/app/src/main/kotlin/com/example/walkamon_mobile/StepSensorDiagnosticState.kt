package com.example.walkamon_mobile

internal enum class TrackedSensorRegistration {
    STEP_DETECTOR,
    STEP_COUNTER,
    MOTION_ACCELERATION,
    MOTION_GYROSCOPE,
}

internal data class StepCollectorConfiguration(
    val captureMode: String,
    val windowMilliseconds: Int,
    val targetSampleHz: Int,
    val contractVersion: Int,
    val bootSessionId: String,
)

internal data class StepSensorRegistrationSnapshot(
    val running: Boolean,
    val detectorRegistered: Boolean,
    val counterRegistered: Boolean,
    val motionAccelerationRegistered: Boolean,
    val motionGyroscopeRegistered: Boolean,
) {
    val anyRegistered: Boolean
        get() = detectorRegistered ||
            counterRegistered ||
            motionAccelerationRegistered ||
            motionGyroscopeRegistered
}

internal data class StepCollectorStartTransition(
    val duplicate: Boolean,
    val previousRegistration: StepSensorRegistrationSnapshot?,
)

internal data class StepRegistrationOutcome(
    val success: Boolean,
    val errorCode: String?,
)

/**
 * Pure state machine used to keep SensorManager registration idempotent and testable.
 */
internal class StepSensorLifecycleState {
    private var configuration: StepCollectorConfiguration? = null
    private var running = false
    private var detectorRegistered = false
    private var counterRegistered = false
    private var motionAccelerationRegistered = false
    private var motionGyroscopeRegistered = false

    fun beginStart(configuration: StepCollectorConfiguration): StepCollectorStartTransition {
        if (running && this.configuration == configuration) {
            return StepCollectorStartTransition(
                duplicate = true,
                previousRegistration = null,
            )
        }

        val previous = if (running) snapshot() else null
        this.configuration = configuration
        running = true
        detectorRegistered = false
        counterRegistered = false
        motionAccelerationRegistered = false
        motionGyroscopeRegistered = false
        return StepCollectorStartTransition(
            duplicate = false,
            previousRegistration = previous,
        )
    }

    fun recordRegistration(
        sensor: TrackedSensorRegistration,
        success: Boolean,
    ): StepRegistrationOutcome {
        when (sensor) {
            TrackedSensorRegistration.STEP_DETECTOR -> detectorRegistered = success
            TrackedSensorRegistration.STEP_COUNTER -> counterRegistered = success
            TrackedSensorRegistration.MOTION_ACCELERATION -> {
                motionAccelerationRegistered = success
            }
            TrackedSensorRegistration.MOTION_GYROSCOPE -> motionGyroscopeRegistered = success
        }
        return StepRegistrationOutcome(
            success = success,
            errorCode = if (success) null else "register_listener_returned_false",
        )
    }

    fun stop(): StepSensorRegistrationSnapshot? {
        if (!running) return null
        val previous = snapshot()
        running = false
        configuration = null
        detectorRegistered = false
        counterRegistered = false
        motionAccelerationRegistered = false
        motionGyroscopeRegistered = false
        return previous
    }

    fun snapshot(): StepSensorRegistrationSnapshot = StepSensorRegistrationSnapshot(
        running = running,
        detectorRegistered = detectorRegistered,
        counterRegistered = counterRegistered,
        motionAccelerationRegistered = motionAccelerationRegistered,
        motionGyroscopeRegistered = motionGyroscopeRegistered,
    )
}

internal data class DetectorCallbackDiagnostic(
    val rawDetectorCallbackIndex: Long,
    val sensorTimestampNs: Long,
    val callbackElapsedRealtimeNs: Long,
    val deliveryDelayNs: Long,
)

internal data class CounterCallbackDiagnostic(
    val rawCounterCallbackIndex: Long,
    val counterRawTotal: Long,
    val sensorTimestampNs: Long,
    val callbackElapsedRealtimeNs: Long,
    val deliveryDelayNs: Long,
    val previousCounter: Long?,
    val derivedDelta: Long?,
)

internal class StepRawCallbackDiagnostics {
    private var detectorCallbackIndex = 0L
    private var counterCallbackIndex = 0L
    private var previousCounter: Long? = null

    fun detector(
        sensorTimestampNs: Long,
        callbackElapsedRealtimeNs: Long,
    ): DetectorCallbackDiagnostic {
        detectorCallbackIndex += 1L
        return DetectorCallbackDiagnostic(
            rawDetectorCallbackIndex = detectorCallbackIndex,
            sensorTimestampNs = sensorTimestampNs,
            callbackElapsedRealtimeNs = callbackElapsedRealtimeNs,
            deliveryDelayNs = callbackElapsedRealtimeNs - sensorTimestampNs,
        )
    }

    fun counter(
        total: Long,
        sensorTimestampNs: Long,
        callbackElapsedRealtimeNs: Long,
    ): CounterCallbackDiagnostic {
        counterCallbackIndex += 1L
        val previous = previousCounter
        previousCounter = total
        return CounterCallbackDiagnostic(
            rawCounterCallbackIndex = counterCallbackIndex,
            counterRawTotal = total,
            sensorTimestampNs = sensorTimestampNs,
            callbackElapsedRealtimeNs = callbackElapsedRealtimeNs,
            deliveryDelayNs = callbackElapsedRealtimeNs - sensorTimestampNs,
            previousCounter = previous,
            derivedDelta = previous?.let { old ->
                if (total >= old) total - old else null
            },
        )
    }

    fun resetCounterTimeline() {
        previousCounter = null
    }
}

internal data class StepSensorRuntimeSnapshot(
    val serviceInstanceId: String,
    val serviceActive: Boolean,
    val screenInteractive: Boolean,
    val wakeLockHeld: Boolean,
)

internal data class StepWakeLockPolicy(
    val continuousDiagnostic: Boolean,
    val timeoutMs: Long?,
) {
    companion object {
        const val PRODUCTION_TIMEOUT_MS = 10 * 60 * 1000L

        fun fromDiagnosticFlag(enabled: Boolean): StepWakeLockPolicy =
            if (enabled) {
                StepWakeLockPolicy(continuousDiagnostic = true, timeoutMs = null)
            } else {
                StepWakeLockPolicy(
                    continuousDiagnostic = false,
                    timeoutMs = PRODUCTION_TIMEOUT_MS,
                )
            }
    }
}

internal data class StepWakeLockAcquireTransition(
    val acquireRequired: Boolean,
    val releasePrevious: Boolean,
)

internal class StepWakeLockLifecycleState {
    private var activePolicy: StepWakeLockPolicy? = null

    fun acquire(policy: StepWakeLockPolicy): StepWakeLockAcquireTransition {
        if (activePolicy == policy) {
            return StepWakeLockAcquireTransition(
                acquireRequired = false,
                releasePrevious = false,
            )
        }
        val transition = StepWakeLockAcquireTransition(
            acquireRequired = true,
            releasePrevious = activePolicy != null,
        )
        activePolicy = policy
        return transition
    }

    fun release(): Boolean {
        if (activePolicy == null) return false
        activePolicy = null
        return true
    }
}

internal object StepDiagnosticLogSampling {
    fun shouldLogRawCallback(index: Long, fullDiagnostic: Boolean): Boolean =
        fullDiagnostic || index <= 3L || index % 100L == 0L
}
