package com.example.walkamon_mobile

import android.util.Log
import org.json.JSONObject

internal object StepSensorDiagnosticLogger {
    private const val TAG = "WalkamonStepDiag"

    fun info(event: String, fields: Map<String, Any?> = emptyMap()) {
        Log.i(TAG, payload(event, fields).toString())
    }

    fun error(
        event: String,
        fields: Map<String, Any?> = emptyMap(),
        throwable: Throwable? = null,
    ) {
        val payload = payload(
            event,
            fields + mapOf(
                "errorClass" to throwable?.javaClass?.name,
                "errorMessage" to throwable?.message,
            ),
        ).toString()
        if (throwable == null) Log.e(TAG, payload) else Log.e(TAG, payload, throwable)
    }

    private fun payload(event: String, fields: Map<String, Any?>): JSONObject =
        JSONObject().apply {
            put("event", event)
            fields.forEach { (key, value) -> put(key, value ?: JSONObject.NULL) }
        }
}
