package com.example.walkamon_mobile

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.PowerManager
import android.os.SystemClock
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition
import java.time.Instant
import java.util.UUID
import kotlin.math.roundToInt
import kotlin.math.sqrt

internal class MotionSensorCollector(
    private val context: Context,
    private val onEvent: (Map<String, Any?>) -> Unit = {},
    private val runtimeSnapshotProvider: (() -> StepSensorRuntimeSnapshot)? = null,
    private val fullCallbackDiagnostics: Boolean = BuildConfig.DEBUG,
) : SensorEventListener {
    private val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val stepDetector = sensors.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
    private val stepCounter = sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    private val linearAcceleration = sensors.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION)
    private val accelerometer = sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val gyroscope = sensors.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
    private val activityClient = ActivityRecognition.getClient(context)
    private val activityIntent = PendingIntent.getBroadcast(
        context,
        9021,
        Intent(context, ActivityRecognitionReceiver::class.java)
            .setAction(ACTIVITY_ACTION),
        PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE
            } else {
                0
            },
    )

    private val collectorInstanceId = UUID.randomUUID().toString()
    private val lifecycle = StepSensorLifecycleState()
    private val callbackDiagnostics = StepRawCallbackDiagnostics()
    private var captureMode = "counter_only"
    private var contractVersion = 2
    private var bootSessionId = ""
    private var targetSampleHz = 25
    private var windowNs = 1_000_000_000L
    private var windowStartNs: Long? = null
    private var anchorEpochMs = 0L
    private var anchorElapsedNs = 0L
    private val gravity = FloatArray(3)
    private var gravityReady = false
    private val accelerationMagnitudes = mutableListOf<Double>()
    private val accelerationTimestamps = mutableListOf<Long>()
    private val gyroscopeMagnitudes = mutableListOf<Double>()
    private val gyroscopeTimestamps = mutableListOf<Long>()
    private var lastAccelerationSlot = -1L

    fun capabilities(): Map<String, Any> = mapOf(
        "stepDetectorAvailable" to (stepDetector != null),
        "stepCounterAvailable" to (stepCounter != null),
        "linearAccelerationAvailable" to (linearAcceleration != null),
        "accelerometerAvailable" to (accelerometer != null),
        "gyroscopeAvailable" to (gyroscope != null),
        "activityRecognitionAvailable" to hasActivityPermission(),
    )

    fun start(
        mode: String,
        requestedWindowMs: Int,
        requestedSampleHz: Int,
        requestedContractVersion: Int,
        currentBootSessionId: String,
        reason: String = "service_start",
    ) {
        val normalizedCaptureMode = normalizedCaptureMode(mode)
        val configuration = StepCollectorConfiguration(
            captureMode = normalizedCaptureMode,
            windowMilliseconds = requestedWindowMs.coerceIn(800, 1200),
            targetSampleHz = requestedSampleHz.coerceIn(15, 40),
            contractVersion = requestedContractVersion,
            bootSessionId = currentBootSessionId,
        )
        val transition = lifecycle.beginStart(configuration)
        if (transition.duplicate) {
            logLifecycle(
                event = "STEP_COLLECTOR_START_IGNORED",
                fields = mapOf(
                    "reason" to reason,
                    "captureMode" to configuration.captureMode,
                    "detail" to "duplicate_configuration",
                ),
            )
            return
        }
        transition.previousRegistration?.let {
            unregisterPlatformListeners(it, reason = "restart")
        }

        contractVersion = requestedContractVersion
        bootSessionId = currentBootSessionId
        captureMode = normalizedCaptureMode
        targetSampleHz = configuration.targetSampleHz
        windowNs = configuration.windowMilliseconds * 1_000_000L
        anchorEpochMs = System.currentTimeMillis()
        anchorElapsedNs = SystemClock.elapsedRealtimeNanos()
        callbackDiagnostics.resetCounterTimeline()
        resetMotionState()

        logLifecycle(
            event = "STEP_COLLECTOR_START",
            fields = mapOf(
                "reason" to reason,
                "captureMode" to captureMode,
                "contractVersion" to contractVersion,
                "bootSessionId" to bootSessionId,
            ),
        )
        logSensorMetadata("step_detector", stepDetector)
        logSensorMetadata("step_counter", stepCounter)

        val samplingPeriodUs = 1_000_000 / targetSampleHz
        if (captureMode == "dual" || captureMode == "detector_only") {
            stepDetector?.let {
                registerSensor(
                    sensor = it,
                    trackedSensor = TrackedSensorRegistration.STEP_DETECTOR,
                    sensorType = "step_detector",
                    samplingPeriodUs = SensorManager.SENSOR_DELAY_NORMAL,
                    reason = reason,
                )
            }
        }
        if (captureMode == "dual" || captureMode == "counter_only") {
            stepCounter?.let {
                registerSensor(
                    sensor = it,
                    trackedSensor = TrackedSensorRegistration.STEP_COUNTER,
                    sensorType = "step_counter",
                    samplingPeriodUs = SensorManager.SENSOR_DELAY_NORMAL,
                    reason = reason,
                )
            }
        }
        (linearAcceleration ?: accelerometer)?.let {
            registerSensor(
                sensor = it,
                trackedSensor = TrackedSensorRegistration.MOTION_ACCELERATION,
                sensorType = if (it.type == Sensor.TYPE_LINEAR_ACCELERATION) {
                    "linear_acceleration"
                } else {
                    "accelerometer"
                },
                samplingPeriodUs = samplingPeriodUs,
                reason = reason,
            )
        }
        gyroscope?.let {
            registerSensor(
                sensor = it,
                trackedSensor = TrackedSensorRegistration.MOTION_GYROSCOPE,
                sensorType = "gyroscope",
                samplingPeriodUs = samplingPeriodUs,
                reason = reason,
            )
        }
        startActivityRecognition()
    }

    fun stop(reason: String = "service_stop") {
        stopSensors(emitFinalWindow = false, reason = reason)
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (!lifecycle.snapshot().running) return
        val callbackElapsedRealtimeNs = SystemClock.elapsedRealtimeNanos()
        when (event.sensor.type) {
            Sensor.TYPE_STEP_DETECTOR -> {
                logDetectorCallback(event.timestamp, callbackElapsedRealtimeNs)
                emitDetectorStep(event.timestamp)
            }
            Sensor.TYPE_STEP_COUNTER -> {
                val total = event.values[0].toLong()
                logCounterCallback(event.timestamp, callbackElapsedRealtimeNs, total)
                emitCounterStep(event.timestamp, total)
            }
            Sensor.TYPE_LINEAR_ACCELERATION -> collectAcceleration(
                event.timestamp,
                event.values[0].toDouble(),
                event.values[1].toDouble(),
                event.values[2].toDouble(),
            )
            Sensor.TYPE_ACCELEROMETER -> {
                val linear = highPass(event.values)
                collectAcceleration(
                    event.timestamp,
                    linear[0].toDouble(),
                    linear[1].toDouble(),
                    linear[2].toDouble(),
                )
            }
            Sensor.TYPE_GYROSCOPE -> collectGyroscope(event)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    fun registrationSnapshot(): StepSensorRegistrationSnapshot = lifecycle.snapshot()

    private fun collectAcceleration(timestampNs: Long, x: Double, y: Double, z: Double) {
        ensureWindow(timestampNs)
        advanceWindows(timestampNs)
        val start = windowStartNs ?: return
        val slotDurationNs = windowNs / targetSampleHz.coerceAtLeast(1)
        val slot = (timestampNs - start) / slotDurationNs.coerceAtLeast(1L)
        if (slot == lastAccelerationSlot) return
        lastAccelerationSlot = slot
        accelerationMagnitudes += sqrt(x * x + y * y + z * z)
        accelerationTimestamps += timestampNs
    }

    private fun collectGyroscope(event: SensorEvent) {
        val start = windowStartNs ?: return
        if (event.timestamp < start || event.timestamp >= start + windowNs) return
        val x = event.values[0].toDouble()
        val y = event.values[1].toDouble()
        val z = event.values[2].toDouble()
        gyroscopeMagnitudes += sqrt(x * x + y * y + z * z)
        gyroscopeTimestamps += event.timestamp
    }

    private fun ensureWindow(timestampNs: Long) {
        if (windowStartNs == null) windowStartNs = timestampNs - timestampNs.mod(windowNs)
    }

    private fun advanceWindows(timestampNs: Long) {
        var start = windowStartNs ?: return
        while (timestampNs >= start + windowNs) {
            emitMotionWindow(start, start + windowNs)
            clearWindow()
            start += windowNs
            windowStartNs = start
        }
    }

    private fun emitDetectorStep(timestampNs: Long) {
        val time = epochMs(timestampNs)
        if (contractVersion >= 3) {
            val clientEventId = UUID.randomUUID().toString()
            onEvent(
                mapOf(
                    "eventType" to "detector",
                    "clientEventId" to clientEventId,
                    "bootSessionId" to bootSessionId,
                    "sensorElapsedRealtimeNs" to timestampNs,
                    "recordedAt" to instant(time),
                ),
            )
            return
        }
        onEvent(
            mapOf(
                "eventType" to "step",
                "sensorMode" to "detector",
                "intervalStartedAt" to instant(time),
                "recordedAt" to instant(time),
                "stepCount" to 1,
                "sensorStartTotal" to null,
                "sensorEndTotal" to null,
            ),
        )
    }

    private fun emitCounterStep(timestampNs: Long, total: Long) {
        if (contractVersion < 3) return
        onEvent(
            mapOf(
                "eventType" to "counter",
                "clientSampleId" to UUID.randomUUID().toString(),
                "bootSessionId" to bootSessionId,
                "sensorElapsedRealtimeNs" to timestampNs,
                "observedAt" to instant(epochMs(timestampNs)),
                "counterTotal" to total,
            ),
        )
    }

    private fun emitMotionWindow(startNs: Long, endNs: Long) {
        if (accelerationMagnitudes.isEmpty()) return
        val features = MotionFeatureMath.calculate(
            accelerationMagnitudes,
            accelerationTimestamps,
            gyroscopeMagnitudes,
            gyroscopeTimestamps,
            targetSampleHz,
            windowNs,
        )
        val activity = ActivityRecognitionReceiver.latest
        val activityFresh = activity != null &&
            SystemClock.elapsedRealtime() - activity.elapsedRealtimeMs <= 15_000L

        onEvent(
            mapOf(
                "eventType" to "motion",
                "bootSessionId" to bootSessionId,
                "windowStartElapsedRealtimeNs" to startNs,
                "windowEndElapsedRealtimeNs" to endNs,
                "windowStartedAt" to instant(epochMs(startNs)),
                "windowEndedAt" to instant(epochMs(endNs)),
                "sampleCount" to accelerationMagnitudes.size,
                "accelerometerSource" to if (linearAcceleration != null) "linear" else "raw_high_pass",
                "gyroscopeAvailable" to (gyroscope != null),
                "activityAvailable" to activityFresh,
                "accelerationRmsMilli" to (features.accelerationRms * 1000.0).roundToInt(),
                "accelerationPeakMilli" to (features.accelerationPeak * 1000.0).roundToInt(),
                "jerkRmsMilli" to (features.jerkRms * 1000.0).roundToInt(),
                "gyroscopeRmsMilli" to features.gyroscopeRms?.let { (it * 1000.0).roundToInt() },
                "gyroscopePeakMilli" to features.gyroscopePeak?.let { (it * 1000.0).roundToInt() },
                "angularTravelMilliDegrees" to features.angularTravelDegrees?.let {
                    (it * 1000.0).roundToInt()
                },
                "dominantFrequencyMilliHz" to (features.dominantFrequencyHz * 1000.0).roundToInt(),
                "periodicityBps" to (features.periodicity * 10000.0).roundToInt().coerceIn(0, 10000),
                "gaitCycleCount" to features.gaitCycleCount,
                "activityCode" to if (activityFresh) activity!!.code else "unknown",
                "activityConfidence" to if (activityFresh) activity!!.confidence else 0,
            ),
        )
    }

    private fun clearWindow() {
        accelerationMagnitudes.clear()
        accelerationTimestamps.clear()
        gyroscopeMagnitudes.clear()
        gyroscopeTimestamps.clear()
        lastAccelerationSlot = -1L
    }

    private fun highPass(values: FloatArray): FloatArray {
        val alpha = 0.8f
        if (!gravityReady) {
            for (index in 0..2) gravity[index] = values[index]
            gravityReady = true
        }
        return FloatArray(3) { index ->
            gravity[index] = alpha * gravity[index] + (1f - alpha) * values[index]
            values[index] - gravity[index]
        }
    }

    private fun epochMs(timestampNs: Long): Long =
        anchorEpochMs + (timestampNs - anchorElapsedNs) / 1_000_000L

    private fun instant(epochMs: Long): String = Instant.ofEpochMilli(epochMs).toString()

    private fun hasActivityPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q ||
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.ACTIVITY_RECOGNITION,
            ) == PackageManager.PERMISSION_GRANTED

    private fun startActivityRecognition() {
        if (!hasActivityPermission()) return
        try {
            activityClient.requestActivityUpdates(1000L, activityIntent)
        } catch (error: SecurityException) {
            ActivityRecognitionReceiver.latest = null
            logLifecycle(
                event = "STEP_ACTIVITY_RECOGNITION_ERROR",
                fields = mapOf("reason" to "permission"),
                throwable = error,
            )
        }
    }

    private fun stopSensors(emitFinalWindow: Boolean, reason: String) {
        val registration = lifecycle.stop() ?: return
        logLifecycle(
            event = "STEP_COLLECTOR_STOP",
            fields = mapOf(
                "reason" to reason,
                "detectorWasRegistered" to registration.detectorRegistered,
                "counterWasRegistered" to registration.counterRegistered,
            ),
        )
        if (emitFinalWindow) {
            val start = windowStartNs
            if (start != null) emitMotionWindow(start, start + windowNs)
        }
        unregisterPlatformListeners(registration, reason)
        resetMotionState()
    }

    private fun normalizedCaptureMode(mode: String): String = when (mode) {
        "dual" -> if (stepDetector != null && stepCounter != null) {
            "dual"
        } else if (stepDetector != null) {
            "detector_only"
        } else {
            "counter_only"
        }
        "detector", "detector_only" -> if (stepDetector != null) {
            "detector_only"
        } else {
            "counter_only"
        }
        else -> "counter_only"
    }

    private fun registerSensor(
        sensor: Sensor,
        trackedSensor: TrackedSensorRegistration,
        sensorType: String,
        samplingPeriodUs: Int,
        reason: String,
    ) {
        val runtime = runtimeSnapshot()
        val result = runCatching {
            sensors.registerListener(this, sensor, samplingPeriodUs)
        }
        val success = result.getOrDefault(false)
        val outcome = lifecycle.recordRegistration(trackedSensor, success)
        val errorCode = if (result.isFailure) {
            "register_listener_exception"
        } else {
            outcome.errorCode
        }
        val fields = runtimeFields(runtime) + mapOf(
            "sensorType" to sensorType,
            "success" to success,
            "elapsedRealtimeNs" to SystemClock.elapsedRealtimeNanos(),
            "utcTime" to Instant.now().toString(),
            "reason" to reason,
            "errorCode" to errorCode,
        )
        if (success) {
            StepSensorDiagnosticLogger.info("STEP_SENSOR_REGISTER", fields)
        } else {
            StepSensorDiagnosticLogger.error(
                event = "STEP_SENSOR_REGISTER",
                fields = fields,
                throwable = result.exceptionOrNull(),
            )
        }
    }

    private fun unregisterPlatformListeners(
        registration: StepSensorRegistrationSnapshot,
        reason: String,
    ) {
        val runtimeBefore = runtimeSnapshot()
        val unregisterResult = runCatching { sensors.unregisterListener(this) }
        val success = unregisterResult.isSuccess
        if (registration.detectorRegistered) {
            logUnregister("step_detector", success, reason, runtimeBefore, unregisterResult.exceptionOrNull())
        }
        if (registration.counterRegistered) {
            logUnregister("step_counter", success, reason, runtimeBefore, unregisterResult.exceptionOrNull())
        }
        runCatching { activityClient.removeActivityUpdates(activityIntent) }
            .onFailure { error ->
                logLifecycle(
                    event = "STEP_ACTIVITY_RECOGNITION_ERROR",
                    fields = mapOf("reason" to reason),
                    throwable = error,
                )
            }
    }

    private fun logUnregister(
        sensorType: String,
        success: Boolean,
        reason: String,
        runtime: StepSensorRuntimeSnapshot,
        throwable: Throwable?,
    ) {
        val fields = runtimeFields(runtime) + mapOf(
            "sensorType" to sensorType,
            "success" to success,
            "elapsedRealtimeNs" to SystemClock.elapsedRealtimeNanos(),
            "utcTime" to Instant.now().toString(),
            "reason" to reason,
        )
        if (success) {
            StepSensorDiagnosticLogger.info("STEP_SENSOR_UNREGISTER", fields)
        } else {
            StepSensorDiagnosticLogger.error(
                event = "STEP_SENSOR_UNREGISTER",
                fields = fields,
                throwable = throwable,
            )
        }
    }

    private fun logDetectorCallback(sensorTimestampNs: Long, callbackElapsedNs: Long) {
        val diagnostic = callbackDiagnostics.detector(sensorTimestampNs, callbackElapsedNs)
        if (!StepDiagnosticLogSampling.shouldLogRawCallback(
                diagnostic.rawDetectorCallbackIndex,
                fullCallbackDiagnostics,
            )
        ) {
            return
        }
        val runtime = runtimeSnapshot()
        StepSensorDiagnosticLogger.info(
            "STEP_DETECTOR_RAW_CALLBACK",
            runtimeFields(runtime) + mapOf(
                "rawDetectorCallbackIndex" to diagnostic.rawDetectorCallbackIndex,
                "sensorTimestampNs" to diagnostic.sensorTimestampNs,
                "callbackElapsedRealtimeNs" to diagnostic.callbackElapsedRealtimeNs,
                "deliveryDelayNs" to diagnostic.deliveryDelayNs,
                "bootSessionId" to bootSessionId,
            ),
        )
    }

    private fun logCounterCallback(
        sensorTimestampNs: Long,
        callbackElapsedNs: Long,
        total: Long,
    ) {
        val diagnostic = callbackDiagnostics.counter(total, sensorTimestampNs, callbackElapsedNs)
        if (!StepDiagnosticLogSampling.shouldLogRawCallback(
                diagnostic.rawCounterCallbackIndex,
                fullCallbackDiagnostics,
            )
        ) {
            return
        }
        val runtime = runtimeSnapshot()
        StepSensorDiagnosticLogger.info(
            "STEP_COUNTER_RAW_CALLBACK",
            runtimeFields(runtime) + mapOf(
                "rawCounterCallbackIndex" to diagnostic.rawCounterCallbackIndex,
                "counterRawTotal" to diagnostic.counterRawTotal,
                "sensorTimestampNs" to diagnostic.sensorTimestampNs,
                "callbackElapsedRealtimeNs" to diagnostic.callbackElapsedRealtimeNs,
                "deliveryDelayNs" to diagnostic.deliveryDelayNs,
                "previousCounter" to diagnostic.previousCounter,
                "derivedDelta" to diagnostic.derivedDelta,
                "bootSessionId" to bootSessionId,
            ),
        )
    }

    private fun logSensorMetadata(sensorType: String, sensor: Sensor?) {
        val runtime = runtimeSnapshot()
        if (sensor == null) {
            StepSensorDiagnosticLogger.info(
                "STEP_SENSOR_METADATA",
                runtimeFields(runtime) + mapOf(
                    "sensorType" to sensorType,
                    "available" to false,
                ),
            )
            return
        }
        StepSensorDiagnosticLogger.info(
            "STEP_SENSOR_METADATA",
            runtimeFields(runtime) + mapOf(
                "sensorType" to sensorType,
                "sensorTypeCode" to sensor.type,
                "available" to true,
                "sensorName" to sensor.name,
                "vendor" to sensor.vendor,
                "version" to sensor.version,
                "isWakeUpSensor" to api21OrUnsupported { sensor.isWakeUpSensor },
                "reportingMode" to api21OrUnsupported { reportingMode(sensor.reportingMode) },
                "fifoMaxEventCount" to api19OrUnsupported { sensor.fifoMaxEventCount },
                "fifoReservedEventCount" to api19OrUnsupported {
                    sensor.fifoReservedEventCount
                },
                "minDelayUs" to sensor.minDelay,
                "maxDelayUs" to api21OrUnsupported { sensor.maxDelay },
                "powerMilliAmp" to sensor.power,
                "resolution" to sensor.resolution,
            ),
        )
    }

    private fun reportingMode(mode: Int): String = when (mode) {
        Sensor.REPORTING_MODE_CONTINUOUS -> "continuous($mode)"
        Sensor.REPORTING_MODE_ON_CHANGE -> "on_change($mode)"
        Sensor.REPORTING_MODE_ONE_SHOT -> "one_shot($mode)"
        Sensor.REPORTING_MODE_SPECIAL_TRIGGER -> "special_trigger($mode)"
        else -> "unknown($mode)"
    }

    private fun api19OrUnsupported(value: () -> Any): Any =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) value() else "unsupported"

    private fun api21OrUnsupported(value: () -> Any): Any =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) value() else "unsupported"

    private fun resetMotionState() {
        windowStartNs = null
        gravityReady = false
        clearWindow()
    }

    private fun runtimeSnapshot(): StepSensorRuntimeSnapshot =
        runtimeSnapshotProvider?.invoke() ?: StepSensorRuntimeSnapshot(
            serviceInstanceId = "standalone",
            serviceActive = lifecycle.snapshot().running,
            screenInteractive = (
                context.getSystemService(Context.POWER_SERVICE) as PowerManager
            ).isInteractive,
            wakeLockHeld = false,
        )

    private fun runtimeFields(runtime: StepSensorRuntimeSnapshot): Map<String, Any?> = mapOf(
        "serviceInstanceId" to runtime.serviceInstanceId,
        "collectorInstanceId" to collectorInstanceId,
        "serviceActive" to runtime.serviceActive,
        "screenInteractive" to runtime.screenInteractive,
        "wakeLockHeld" to runtime.wakeLockHeld,
    )

    private fun logLifecycle(
        event: String,
        fields: Map<String, Any?>,
        throwable: Throwable? = null,
    ) {
        val allFields = runtimeFields(runtimeSnapshot()) +
            mapOf(
                "elapsedRealtimeNs" to SystemClock.elapsedRealtimeNanos(),
                "utcTime" to Instant.now().toString(),
            ) + fields
        if (throwable == null) {
            StepSensorDiagnosticLogger.info(event, allFields)
        } else {
            StepSensorDiagnosticLogger.error(event, allFields, throwable)
        }
    }

    companion object {
        private const val ACTIVITY_ACTION = "com.example.walkamon_mobile.ACTIVITY_UPDATE"
    }
}
