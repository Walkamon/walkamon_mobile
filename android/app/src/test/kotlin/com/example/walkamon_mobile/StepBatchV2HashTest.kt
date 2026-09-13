package com.example.walkamon_mobile

import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Test

class StepBatchV2HashTest {
    private val sessionId = "11111111-2222-3333-4444-555555555555"
    // Fixed vector from backend StepSensorCanonicalizerTests.ComputeHash_V2_IncludesMotionEvidence.
    private val backendHash = "3A1F6B8310F18DEA996E098952443ABA6A219CF7BA41C96C498167A4D39DECD2"

    private fun payload() = JSONObject(
        """{
          "contractVersion":2,"sequence":1,"nonce":"NONCE","attestationToken":"",
          "events":[
            {"intervalStartedAt":"2026-07-17T03:00:01.000Z","recordedAt":"2026-07-17T03:00:02.000Z","stepCount":2,"sensorStartTotal":1200,"sensorEndTotal":1202},
            {"intervalStartedAt":"2026-07-17T03:00:02.000Z","recordedAt":"2026-07-17T03:00:03.000Z","stepCount":1}
          ],
          "motionWindows":[{
            "windowStartedAt":"2026-07-17T03:00:01.000Z","windowEndedAt":"2026-07-17T03:00:02.000Z",
            "sampleCount":25,"accelerometerSource":"linear","gyroscopeAvailable":true,"activityAvailable":true,
            "accelerationRmsMilli":2310,"accelerationPeakMilli":8420,"jerkRmsMilli":12700,
            "gyroscopeRmsMilli":740,"gyroscopePeakMilli":3180,"angularTravelMilliDegrees":24500,
            "dominantFrequencyMilliHz":1820,"periodicityBps":7800,"gaitCycleCount":2,
            "activityCode":"walking","activityConfidence":78
          }]
        }""".trimIndent(),
    )

    private fun hash(body: JSONObject) = computeStepBatchV2Hash(sessionId, "counter", body)

    @Test
    fun angularTravelOnlyMatchesBackendGoldenVector() {
        assertEquals(backendHash, hash(payload()))
        assertTrue(hash(payload()).matches(Regex("[0-9A-F]{64}")))
    }

    @Test
    fun legacyOrientationAndNullAngularRemainCompatible() {
        val body = payload()
        val window = body.getJSONArray("motionWindows").getJSONObject(0)
        window.put("orientationDeltaMilliDegrees", window.remove("angularTravelMilliDegrees"))
        assertEquals(backendHash, hash(body))
        window.put("angularTravelMilliDegrees", JSONObject.NULL)
        assertEquals(backendHash, hash(body))
    }

    @Test
    fun zeroAngularIsAValueAndTakesPrecedenceOverLegacy() {
        val body = payload()
        val window = body.getJSONArray("motionWindows").getJSONObject(0)
        window.put("angularTravelMilliDegrees", 0)
        val zeroHash = hash(body)
        assertNotEquals(backendHash, zeroHash)
        window.put("orientationDeltaMilliDegrees", 999)
        assertEquals(zeroHash, hash(body))
        window.put("angularTravelMilliDegrees", JSONObject.NULL)
        assertNotEquals(zeroHash, hash(body))
    }

    @Test
    fun timezoneEquivalentInputsMatchAndChangedEvidenceDoesNot() {
        val body = payload()
        body.getJSONArray("events").getJSONObject(0)
            .put("intervalStartedAt", "2026-07-17T10:00:01.000+07:00")
        assertEquals(backendHash, hash(body))
        body.getJSONArray("motionWindows").getJSONObject(0).put("angularTravelMilliDegrees", 24501)
        assertNotEquals(backendHash, hash(body))
        val events = payload().getJSONArray("events")
        val reordered = payload().put("events", org.json.JSONArray().put(events.getJSONObject(1)).put(events.getJSONObject(0)))
        assertNotEquals(backendHash, hash(reordered))
    }

    private fun pending(body: JSONObject, hash: String) = PendingStepBatch(
        payloadHash = hash, body = body.put("payloadHash", hash).put("attestationToken", "old-bound-proof"),
        eventIds = listOf(10L, 11L), windowIds = listOf(20L),
        attestationToken = "old-bound-proof", attestationRequestedAtMs = 123L,
    )

    @Test
    fun repairingCachedV2PreservesSamplesAndSequenceButReattests() {
        val old = pending(payload(), "BA462EDA3B5A864118D5ED5E532375B270D56952ED982124B86B299565A9D3C6")
        val oldBody = old.body.toString()
        val fixed = repairPendingV2Hash(sessionId, "counter", old)
        assertEquals(backendHash, fixed.payloadHash)
        assertEquals(backendHash, fixed.body.getString("payloadHash"))
        assertEquals(old.eventIds, fixed.eventIds)
        assertEquals(old.windowIds, fixed.windowIds)
        assertEquals(old.body.getJSONArray("events").toString(), fixed.body.getJSONArray("events").toString())
        assertEquals(old.body.getJSONArray("motionWindows").toString(), fixed.body.getJSONArray("motionWindows").toString())
        assertEquals(1, fixed.body.getInt("sequence"))
        assertEquals("NONCE", fixed.body.getString("nonce"))
        assertNull(fixed.attestationToken)
        assertNull(fixed.attestationRequestedAtMs)
        assertEquals("", fixed.body.getString("attestationToken"))
        assertEquals(oldBody, old.body.toString())
        assertSame(fixed, repairPendingV2Hash(sessionId, "counter", fixed))
    }

    @Test
    fun validCachedV2RetainsAttestationAndV3IsUntouched() {
        val correct = pending(payload(), backendHash)
        assertSame(correct, repairPendingV2Hash(sessionId, "counter", correct))
        val v3 = pending(JSONObject().put("contractVersion", 3), "v3-hash")
        assertSame(v3, repairPendingV2Hash(sessionId, "counter", v3))
    }
}
