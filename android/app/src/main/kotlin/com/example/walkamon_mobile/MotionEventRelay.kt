package com.example.walkamon_mobile

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object MotionEventRelay : EventChannel.StreamHandler {
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    fun emit(event: Map<String, Any?>) {
        mainHandler.post { sink?.success(event) }
    }
}
