package com.jimmy.religiousapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
            putExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY, intent.getStringExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY))
            putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, intent.getStringExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME))
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
