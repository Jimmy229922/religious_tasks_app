package com.jimmy.religiousapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prayerKey = intent.getStringExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY) ?: "fajr"
        val prayerName = intent.getStringExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME) ?: "الصلاة"
        val soundType = intent.getIntExtra(AdhanPlaybackService.EXTRA_SOUND_TYPE, 0)
        val moazzenId = intent.getStringExtra(AdhanPlaybackService.EXTRA_MOAZZEN_ID) ?: "default"

        // For silent prayer notifications, post directly without starting a background FGS
        if (soundType == 0) {
            AdhanPlaybackService.postAlertNotification(
                context = context,
                prayerKey = prayerKey,
                prayerName = prayerName,
                playSound = false
            )
            return
        }

        val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
            putExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY, prayerKey)
            putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanPlaybackService.EXTRA_SOUND_TYPE, soundType)
            putExtra(AdhanPlaybackService.EXTRA_MOAZZEN_ID, moazzenId)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            // Fallback for Android 12+ / strict OEMs if background FGS start was denied:
            // Guarantee the user still receives a visible & audible notification.
            Log.e("AdhanAlarmReceiver", "FGS start blocked, posting fallback notification: ${e.message}")
            AdhanPlaybackService.postAlertNotification(
                context = context,
                prayerKey = prayerKey,
                prayerName = prayerName,
                playSound = true
            )
        }
    }
}
