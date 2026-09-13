package com.example.walkamon_mobile

import org.json.JSONObject
import java.nio.charset.StandardCharsets
import java.security.MessageDigest

/** Hash the API payload itself so queued and freshly collected batches use the same contract. */
internal fun computeStepBatchV2Hash(
    sessionId: String,
    sensorMode: String,
    body: JSONObject,
): String {
    val lines = mutableListOf(
        "V2", sessionId.lowercase(), body.getInt("sequence").toString(),
        body.getString("nonce"), sensorMode,
    )
    val events = body.getJSONArray("events")
    for (index in 0 until events.length()) {
        val event = events.getJSONObject(index)
        lines += listOf(
            "E", parseServerUtcMillis(event.getString("intervalStartedAt")),
            parseServerUtcMillis(event.getString("recordedAt")), event.getInt("stepCount"),
            event.hashField("sensorStartTotal"), event.hashField("sensorEndTotal"),
        ).joinToString(":")
    }
    val windows = body.getJSONArray("motionWindows")
    for (index in 0 until windows.length()) {
        val window = windows.getJSONObject(index)
        val angularTravel = if (window.isNull("angularTravelMilliDegrees")) {
            window.hashField("orientationDeltaMilliDegrees")
        } else {
            window.hashField("angularTravelMilliDegrees")
        }
        lines += listOf(
            "M", parseServerUtcMillis(window.getString("windowStartedAt")),
            parseServerUtcMillis(window.getString("windowEndedAt")), window.getInt("sampleCount"),
            window.getString("accelerometerSource"), if (window.getBoolean("gyroscopeAvailable")) 1 else 0,
            if (window.getBoolean("activityAvailable")) 1 else 0,
            window.getInt("accelerationRmsMilli"), window.getInt("accelerationPeakMilli"),
            window.getInt("jerkRmsMilli"), window.hashField("gyroscopeRmsMilli"),
            window.hashField("gyroscopePeakMilli"), angularTravel,
            window.getInt("dominantFrequencyMilliHz"), window.getInt("periodicityBps"),
            window.getInt("gaitCycleCount"), window.getString("activityCode"), window.getInt("activityConfidence"),
        ).joinToString(":")
    }
    return MessageDigest.getInstance("SHA-256")
        .digest(lines.joinToString("\n").toByteArray(StandardCharsets.UTF_8))
        .joinToString("") { "%02X".format(it) }
}

/** Upgrades must also repair the serialized batch that otherwise retries its old hash forever. */
internal fun repairPendingV2Hash(
    sessionId: String,
    sensorMode: String,
    batch: PendingStepBatch,
): PendingStepBatch {
    if (batch.body.optInt("contractVersion") != 2) return batch
    val hash = computeStepBatchV2Hash(sessionId, sensorMode, batch.body)
    if (batch.payloadHash == hash && batch.body.optString("payloadHash") == hash) return batch
    return batch.copy(
        payloadHash = hash,
        body = JSONObject(batch.body.toString()).put("payloadHash", hash).put("attestationToken", ""),
        attestationToken = null,
        attestationRequestedAtMs = null,
    )
}

private fun JSONObject.hashField(key: String): String = if (isNull(key)) "" else get(key).toString()
