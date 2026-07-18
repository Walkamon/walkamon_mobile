package com.example.walkamon_mobile

import kotlin.math.PI
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

data class MotionFeatures(
    val accelerationRms: Double,
    val accelerationPeak: Double,
    val jerkRms: Double,
    val gyroscopeRms: Double?,
    val gyroscopePeak: Double?,
    val orientationDeltaDegrees: Double?,
    val dominantFrequencyHz: Double,
    val periodicity: Double,
    val gaitCycleCount: Int,
)

object MotionFeatureMath {
    fun calculate(
        acceleration: List<Double>,
        accelerationTimestamps: List<Long>,
        gyroscope: List<Double>,
        gyroscopeTimestamps: List<Long>,
        targetSampleHz: Int,
        windowNs: Long,
    ): MotionFeatures {
        val spectral = spectralFeatures(acceleration, windowNs)
        return MotionFeatures(
            accelerationRms = rms(acceleration),
            accelerationPeak = acceleration.maxOrNull() ?: 0.0,
            jerkRms = jerkRms(acceleration, accelerationTimestamps),
            gyroscopeRms = gyroscope.takeIf { it.isNotEmpty() }?.let(::rms),
            gyroscopePeak = gyroscope.maxOrNull(),
            orientationDeltaDegrees = orientationDeltaDegrees(
                gyroscope,
                gyroscopeTimestamps,
            ),
            dominantFrequencyHz = spectral.first,
            periodicity = spectral.second,
            gaitCycleCount = gaitCycleCount(acceleration, targetSampleHz),
        )
    }

    private fun jerkRms(values: List<Double>, timestamps: List<Long>): Double {
        if (values.size < 2 || values.size != timestamps.size) return 0.0
        val jerks = mutableListOf<Double>()
        for (index in 1 until values.size) {
            val seconds = (timestamps[index] - timestamps[index - 1]) / 1e9
            if (seconds > 0) {
                jerks += kotlin.math.abs(values[index] - values[index - 1]) / seconds
            }
        }
        return if (jerks.isEmpty()) 0.0 else rms(jerks)
    }

    private fun orientationDeltaDegrees(
        values: List<Double>,
        timestamps: List<Long>,
    ): Double? {
        if (values.size < 2 || values.size != timestamps.size) return null
        var radians = 0.0
        for (index in 1 until values.size) {
            val seconds = (timestamps[index] - timestamps[index - 1]) / 1e9
            if (seconds > 0) {
                radians += (values[index] + values[index - 1]) * 0.5 * seconds
            }
        }
        return radians * 180.0 / PI
    }

    private fun spectralFeatures(
        values: List<Double>,
        windowNs: Long,
    ): Pair<Double, Double> {
        if (values.size < 8) return 0.0 to 0.0
        val mean = values.average()
        val centered = values.map { it - mean }
        if (centered.sumOf { it * it } <= 1e-9) return 0.0 to 0.0
        val rate = values.size * 1_000_000_000.0 / windowNs
        val minLag = max(2, ceil(rate / 4.0).toInt())
        val maxLag = min(values.size - 2, ceil(rate / 0.6).toInt())
        if (maxLag < minLag) return 0.0 to 0.0
        var bestLag = minLag
        var best = 0.0
        for (lag in minLag..maxLag) {
            var numerator = 0.0
            var left = 0.0
            var right = 0.0
            for (index in 0 until centered.size - lag) {
                numerator += centered[index] * centered[index + lag]
                left += centered[index] * centered[index]
                right += centered[index + lag] * centered[index + lag]
            }
            val denominator = sqrt(left * right)
            val correlation = if (denominator <= 1e-9) 0.0 else numerator / denominator
            if (correlation > best) {
                best = correlation
                bestLag = lag
            }
        }
        return (rate / bestLag) to best.coerceIn(0.0, 1.0)
    }

    private fun gaitCycleCount(values: List<Double>, targetSampleHz: Int): Int {
        if (values.size < 5) return 0
        val mean = values.average()
        val deviation = sqrt(values.sumOf { (it - mean) * (it - mean) } / values.size)
        val threshold = mean + deviation * 0.5
        val minGap = max(2, targetSampleHz / 4)
        var count = 0
        var lastPeak = -minGap
        for (index in 1 until values.size - 1) {
            if (index - lastPeak >= minGap &&
                values[index] >= threshold &&
                values[index] > values[index - 1] &&
                values[index] >= values[index + 1]
            ) {
                count++
                lastPeak = index
            }
        }
        return count
    }

    private fun rms(values: List<Double>): Double =
        if (values.isEmpty()) 0.0 else sqrt(values.sumOf { it * it } / values.size)
}
