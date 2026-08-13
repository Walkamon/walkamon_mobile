package com.example.walkamon_mobile

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class StepSensorDiagnosticStateTest {
    private val configuration = StepCollectorConfiguration(
        captureMode = "dual",
        windowMilliseconds = 1000,
        targetSampleHz = 25,
        contractVersion = 3,
        bootSessionId = "boot-a",
    )

    @Test
    fun successfulDetectorRegistrationUpdatesState() {
        val state = StepSensorLifecycleState()
        state.beginStart(configuration)

        val outcome = state.recordRegistration(
            TrackedSensorRegistration.STEP_DETECTOR,
            success = true,
        )

        assertTrue(outcome.success)
        assertNull(outcome.errorCode)
        assertTrue(state.snapshot().detectorRegistered)
    }

    @Test
    fun failedRegistrationDoesNotPretendListenerIsRegistered() {
        val state = StepSensorLifecycleState()
        state.beginStart(configuration)

        val outcome = state.recordRegistration(
            TrackedSensorRegistration.STEP_DETECTOR,
            success = false,
        )

        assertFalse(outcome.success)
        assertEquals("register_listener_returned_false", outcome.errorCode)
        assertFalse(state.snapshot().detectorRegistered)
    }

    @Test
    fun duplicateStartDoesNotRequestListenerReplacement() {
        val state = StepSensorLifecycleState()
        state.beginStart(configuration)
        state.recordRegistration(TrackedSensorRegistration.STEP_DETECTOR, true)

        val transition = state.beginStart(configuration)

        assertTrue(transition.duplicate)
        assertNull(transition.previousRegistration)
        assertTrue(state.snapshot().detectorRegistered)
    }

    @Test
    fun changedStartReturnsPreviousRegistrationForSingleReplacement() {
        val state = StepSensorLifecycleState()
        state.beginStart(configuration)
        state.recordRegistration(TrackedSensorRegistration.STEP_DETECTOR, true)

        val transition = state.beginStart(configuration.copy(bootSessionId = "boot-b"))

        assertFalse(transition.duplicate)
        assertNotNull(transition.previousRegistration)
        assertTrue(transition.previousRegistration!!.detectorRegistered)
        assertFalse(state.snapshot().detectorRegistered)
    }

    @Test
    fun serviceStopRequestsUnregisterOnlyOnce() {
        val state = StepSensorLifecycleState()
        state.beginStart(configuration)
        state.recordRegistration(TrackedSensorRegistration.STEP_DETECTOR, true)

        assertNotNull(state.stop())
        assertNull(state.stop())
    }

    @Test
    fun detectorCallbackIndexIncrementsAndPreservesSensorTimestamp() {
        val diagnostics = StepRawCallbackDiagnostics()

        val first = diagnostics.detector(100L, 150L)
        val second = diagnostics.detector(200L, 275L)

        assertEquals(1L, first.rawDetectorCallbackIndex)
        assertEquals(2L, second.rawDetectorCallbackIndex)
        assertEquals(200L, second.sensorTimestampNs)
    }

    @Test
    fun detectorDeliveryDelayUsesMonotonicCallbackMinusSensorTimestamp() {
        val result = StepRawCallbackDiagnostics().detector(
            sensorTimestampNs = 1_000L,
            callbackElapsedRealtimeNs = 1_275L,
        )

        assertEquals(275L, result.deliveryDelayNs)
    }

    @Test
    fun counterDiagnosticReportsPreviousAndDerivedDeltaWithoutSynthesizingSteps() {
        val diagnostics = StepRawCallbackDiagnostics()
        val baseline = diagnostics.counter(10L, 100L, 110L)
        val next = diagnostics.counter(16L, 200L, 230L)

        assertNull(baseline.previousCounter)
        assertNull(baseline.derivedDelta)
        assertEquals(1L, baseline.rawCounterCallbackIndex)
        assertEquals(2L, next.rawCounterCallbackIndex)
        assertEquals(10L, next.previousCounter)
        assertEquals(6L, next.derivedDelta)
        assertEquals(30L, next.deliveryDelayNs)
    }

    @Test
    fun diagnosticWakeLockOffKeepsProductionTimeout() {
        val policy = StepWakeLockPolicy.fromDiagnosticFlag(false)

        assertFalse(policy.continuousDiagnostic)
        assertEquals(StepWakeLockPolicy.PRODUCTION_TIMEOUT_MS, policy.timeoutMs)
    }

    @Test
    fun diagnosticWakeLockOnUsesContinuousLifecycleBoundLock() {
        val policy = StepWakeLockPolicy.fromDiagnosticFlag(true)

        assertTrue(policy.continuousDiagnostic)
        assertNull(policy.timeoutMs)
    }

    @Test
    fun wakeLockLifecycleAcquiresOnceAndReleasesOnce() {
        val lifecycle = StepWakeLockLifecycleState()
        val policy = StepWakeLockPolicy.fromDiagnosticFlag(true)

        val firstAcquire = lifecycle.acquire(policy)
        val duplicateAcquire = lifecycle.acquire(policy)

        assertTrue(firstAcquire.acquireRequired)
        assertFalse(firstAcquire.releasePrevious)
        assertFalse(duplicateAcquire.acquireRequired)
        assertTrue(lifecycle.release())
        assertFalse(lifecycle.release())
    }

    @Test
    fun changingWakeLockPolicyRequestsReplacement() {
        val lifecycle = StepWakeLockLifecycleState()
        lifecycle.acquire(StepWakeLockPolicy.fromDiagnosticFlag(false))

        val transition = lifecycle.acquire(StepWakeLockPolicy.fromDiagnosticFlag(true))

        assertTrue(transition.acquireRequired)
        assertTrue(transition.releasePrevious)
    }

    @Test
    fun productionRawCallbackLoggingIsBounded() {
        assertTrue(StepDiagnosticLogSampling.shouldLogRawCallback(1L, false))
        assertFalse(StepDiagnosticLogSampling.shouldLogRawCallback(4L, false))
        assertTrue(StepDiagnosticLogSampling.shouldLogRawCallback(100L, false))
        assertTrue(StepDiagnosticLogSampling.shouldLogRawCallback(4L, true))
    }
}
