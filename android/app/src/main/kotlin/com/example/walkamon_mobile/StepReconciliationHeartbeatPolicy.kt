package com.example.walkamon_mobile

internal object StepReconciliationHeartbeatPolicy {
    fun shouldKeepHeartbeatAlive(
        hasServerPendingDetector: Boolean,
        serverReconciliationPending: Boolean,
    ): Boolean = hasServerPendingDetector || serverReconciliationPending
}
