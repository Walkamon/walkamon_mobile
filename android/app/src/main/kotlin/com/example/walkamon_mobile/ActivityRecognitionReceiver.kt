package com.example.walkamon_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import com.google.android.gms.location.ActivityRecognitionResult
import com.google.android.gms.location.DetectedActivity

class ActivityRecognitionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!ActivityRecognitionResult.hasResult(intent)) return
        val activity = ActivityRecognitionResult.extractResult(intent)
            ?.probableActivities
            ?.maxByOrNull { it.confidence }
            ?: return
        latest = ActivitySnapshot(
            code = mapActivity(activity.type),
            confidence = activity.confidence.coerceIn(0, 100),
            elapsedRealtimeMs = SystemClock.elapsedRealtime(),
        )
    }

    companion object {
        @Volatile
        var latest: ActivitySnapshot? = null

        private fun mapActivity(type: Int): String = when (type) {
            DetectedActivity.WALKING -> "walking"
            DetectedActivity.RUNNING -> "running"
            DetectedActivity.ON_FOOT -> "walking"
            DetectedActivity.STILL -> "still"
            DetectedActivity.IN_VEHICLE -> "vehicle"
            DetectedActivity.ON_BICYCLE -> "bicycle"
            else -> "unknown"
        }
    }
}

data class ActivitySnapshot(
    val code: String,
    val confidence: Int,
    val elapsedRealtimeMs: Long,
)
