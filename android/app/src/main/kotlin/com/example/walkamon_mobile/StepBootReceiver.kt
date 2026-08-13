package com.example.walkamon_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restores the health foreground service after a real device reboot when the
 * user previously enabled tracking. WorkManager is deliberately not used to
 * register realtime sensors.
 */
class StepBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) {
            return
        }
        BackgroundStepService.resumeAfterBoot(context.applicationContext)
    }
}
