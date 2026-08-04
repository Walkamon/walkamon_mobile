package com.example.walkamon_mobile

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object MotionEventRelay : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var sink: EventChannel.EventSink? = null

    @Volatile
    private var latestTrackingStatus: Map<String, Any?>? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
        latestTrackingStatus?.let { status ->
            mainHandler.post {
                if (sink === events) events.success(status)
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun emit(event: Map<String, Any?>) {
        if (event["eventType"] == "tracking_status") {
            latestTrackingStatus = event.toMap()
        }
        mainHandler.post { sink?.success(event) }
    }
}
