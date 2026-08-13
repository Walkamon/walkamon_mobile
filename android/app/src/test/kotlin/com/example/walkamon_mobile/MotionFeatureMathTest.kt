package com.example.walkamon_mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.PI
import kotlin.math.sin

class MotionFeatureMathTest {
    @Test
    fun walkingLikeSignalFindsGaitFrequency() {
        val samples = (0 until 25).map { index ->
            2.0 + sin(2.0 * PI * 2.0 * index / 25.0)
        }
        val timestamps = (0 until 25).map { it * 40_000_000L }

        val result = MotionFeatureMath.calculate(
            samples,
            timestamps,
            emptyList(),
            emptyList(),
            25,
            1_000_000_000L,
        )

        assertTrue(result.dominantFrequencyHz in 1.7..2.2)
        assertTrue(result.periodicity > 0.7)
        assertTrue(result.gaitCycleCount >= 1)
        assertNull(result.gyroscopeRms)
    }

    @Test
    fun highEnergySignalKeepsPhysicalMagnitude() {
        val samples = listOf(0.0, 22.0, 0.0, 24.0, 0.0)
        val timestamps = (0 until 5).map { it * 40_000_000L }

        val result = MotionFeatureMath.calculate(
            samples,
            timestamps,
            listOf(8.0, 8.0, 8.0),
            listOf(0L, 40_000_000L, 80_000_000L),
            25,
            1_000_000_000L,
        )

        assertEquals(24.0, result.accelerationPeak, 0.001)
        assertTrue(result.jerkRms > 30.0)
        assertEquals(8.0, result.gyroscopeRms!!, 0.001)
        assertTrue(result.angularTravelDegrees!! > 0.0)
    }
}
