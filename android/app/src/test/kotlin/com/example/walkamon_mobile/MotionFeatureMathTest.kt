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
    }

    @Test
    fun counterIntervalAfterIdleIsBoundedToOneSecondForOneStep() {
        val previous = 0L
        val recorded = 30_000_000_000L

        val start = CounterIntervalMath.startNs(previous, recorded, 1)

        assertEquals(29_000_000_000L, start)
    }

    @Test
    fun counterDeltaIsSplitIntoMonotonicCadenceBoundedIntervals() {
        val previous = 0L
        val recorded = 30_000_000_000L

        val intervals = CounterIntervalMath.intervals(previous, recorded, 100)

        assertEquals(3, intervals.size)
        assertEquals(listOf(40, 40, 20), intervals.map { it.stepCount })
        assertEquals(recorded, intervals.last().endNs)
        assertTrue(intervals.zipWithNext().all { (left, right) ->
            left.endNs == right.startNs
        })
        assertTrue(intervals.all { it.endNs - it.startNs in 1_000_000_000L..10_000_000_000L })
    }
}
