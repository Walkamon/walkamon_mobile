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
import android.os.SystemClock
import androidx.core.content.ContextCompat
import com.google.android.gms.location.ActivityRecognition
import java.time.Instant
import kotlin.math.roundToInt
import kotlin.math.sqrt

class MotionSensorCollector(
    private val context: Context,
    private val onEvent: (Map<String, Any?>) -> Unit = {},
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

    private var running = false
    private var sensorMode = "counter"
    private var targetSampleHz = 25
    private var windowNs = 1_000_000_000L
    private var windowStartNs: Long? = null
    private var anchorEpochMs = 0L
    private var anchorElapsedNs = 0L
    private var lastCounterTotal: Long? = null
    private var lastCounterTimestampNs: Long? = null
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

    fun start(mode: String, requestedWindowMs: Int, requestedSampleHz: Int) {
        stopSensors(emitFinalWindow = false)
        sensorMode = if (mode == "detector" && stepDetector != null) "detector" else "counter"
        targetSampleHz = requestedSampleHz.coerceIn(15, 40)
        windowNs = requestedWindowMs.coerceIn(800, 1200) * 1_000_000L
        anchorEpochMs = System.currentTimeMillis()
        anchorElapsedNs = SystemClock.elapsedRealtimeNanos()
        running = true

        val samplingPeriodUs = 1_000_000 / targetSampleHz
        val stepSensor = if (sensorMode == "detector") stepDetector else stepCounter
        stepSensor?.let { sensors.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL) }
        (linearAcceleration ?: accelerometer)?.let {
            sensors.registerListener(this, it, samplingPeriodUs)
        }
        gyroscope?.let { sensors.registerListener(this, it, samplingPeriodUs) }
        startActivityRecognition()
    }

    fun stop() {
        stopSensors(emitFinalWindow = false)
    }

    override fun onSensorChanged(event: SensorEvent) {
        if (!running) return
        when (event.sensor.type) {
            Sensor.TYPE_STEP_DETECTOR -> emitDetectorStep(event.timestamp)
            Sensor.TYPE_STEP_COUNTER -> emitCounterStep(event.timestamp, event.values[0].toLong())
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
        val previousTotal = lastCounterTotal
        val previousTime = lastCounterTimestampNs
        lastCounterTotal = total
        lastCounterTimestampNs = timestampNs
        val previousSensorTotal = previousTotal ?: return
        val previousSensorTime = previousTime ?: return
        if (total <= previousSensorTotal) return
        val stepCount = (total - previousSensorTotal)
            .coerceAtMost(Int.MAX_VALUE.toLong())
            .toInt()
        // TYPE_STEP_COUNTER can stay silent while the user is idle. Split a
        // large delta into monotonic, cadence-bounded events so the BE can
        // validate continuity without turning the first callback after a
        // pause into a stale or >4 steps/sec interval.
        var sensorStartTotal = previousSensorTotal
        CounterIntervalMath.intervals(previousSensorTime, timestampNs, stepCount)
            .forEach { interval ->
                val sensorEndTotal = sensorStartTotal + interval.stepCount
                onEvent(
                    mapOf(
                        "eventType" to "step",
                        "sensorMode" to "counter",
                        "intervalStartedAt" to instant(epochMs(interval.startNs)),
                        "recordedAt" to instant(epochMs(interval.endNs)),
                        "stepCount" to interval.stepCount,
                        "sensorStartTotal" to sensorStartTotal,
                        "sensorEndTotal" to sensorEndTotal,
                    ),
                )
                sensorStartTotal = sensorEndTotal
            }
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
                "orientationDeltaMilliDegrees" to features.orientationDeltaDegrees?.let {
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
        } catch (_: SecurityException) {
            ActivityRecognitionReceiver.latest = null
        }
    }

    private fun stopSensors(emitFinalWindow: Boolean) {
        if (emitFinalWindow) {
            val start = windowStartNs
            if (start != null) emitMotionWindow(start, start + windowNs)
        }
        sensors.unregisterListener(this)
        activityClient.removeActivityUpdates(activityIntent)
        running = false
        windowStartNs = null
        lastCounterTotal = null
        lastCounterTimestampNs = null
        gravityReady = false
        clearWindow()
    }

    companion object {
        private const val ACTIVITY_ACTION = "com.example.walkamon_mobile.ACTIVITY_UPDATE"
    }
}

internal object CounterIntervalMath {
    data class Interval(
        val startNs: Long,
        val endNs: Long,
        val stepCount: Int,
    )

    fun intervals(previousTimeNs: Long, timestampNs: Long, stepCount: Int): List<Interval> {
        if (stepCount <= 0 || timestampNs <= previousTimeNs) return emptyList()
        val chunks = mutableListOf<Int>()
        var remaining = stepCount
        while (remaining > 0) {
            val chunk = remaining.coerceAtMost(MAX_STEPS_PER_EVENT)
            chunks += chunk
            remaining -= chunk
        }
        val totalDurationNs = chunks.sumOf(::durationNs)
        var cursorNs = timestampNs - totalDurationNs
        return chunks.map { chunk ->
            val endNs = cursorNs + durationNs(chunk)
            Interval(cursorNs, endNs, chunk).also { cursorNs = endNs }
        }
    }

    fun startNs(previousTimeNs: Long, timestampNs: Long, stepCount: Int): Long {
        return intervals(previousTimeNs, timestampNs, stepCount)
            .firstOrNull()
            ?.startNs
            ?: timestampNs
    }

    private fun durationNs(stepCount: Int): Long =
        (stepCount.coerceAtLeast(1) * 250_000_000L)
            .coerceIn(1_000_000_000L, 10_000_000_000L)

    private const val MAX_STEPS_PER_EVENT = 40
}
