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
            putExtra(AdhanPlaybackService.EXTRA_SOUND_TYPE, intent.getIntExtra(AdhanPlaybackService.EXTRA_SOUND_TYPE, 0))
            putExtra(AdhanPlaybackService.EXTRA_MOAZZEN_ID, intent.getStringExtra(AdhanPlaybackService.EXTRA_MOAZZEN_ID))
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
