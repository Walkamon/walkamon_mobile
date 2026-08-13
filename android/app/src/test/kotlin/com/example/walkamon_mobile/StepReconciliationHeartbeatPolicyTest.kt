package com.example.walkamon_mobile

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class StepReconciliationHeartbeatPolicyTest {
    @Test
    fun `server reconciliation pending keeps D zero heartbeat alive`() {
        assertTrue(
            StepReconciliationHeartbeatPolicy.shouldKeepHeartbeatAlive(
                hasServerPendingDetector = false,
                serverReconciliationPending = true,
            ),
        )
    }

    @Test
    fun `server pending detector keeps existing heartbeat behavior`() {
        assertTrue(
            StepReconciliationHeartbeatPolicy.shouldKeepHeartbeatAlive(
                hasServerPendingDetector = true,
                serverReconciliationPending = false,
            ),
        )
    }

    @Test
    fun `settled response with no detector pending stops heartbeat`() {
        assertFalse(
            StepReconciliationHeartbeatPolicy.shouldKeepHeartbeatAlive(
                hasServerPendingDetector = false,
                serverReconciliationPending = false,
            ),
        )
    }
}
