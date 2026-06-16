package com.jimmy.religiousapp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object NativeAdhanScheduler {
    fun schedule(
        context: Context,
        requestCode: Int,
        prayerKey: String,
        prayerName: String,
        timeMillis: Long,
        soundType: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(context, requestCode, prayerKey, prayerName, soundType)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
        }
    }

    fun cancel(context: Context, requestCode: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent(context, requestCode, "", "", 0))
    }

    private fun pendingIntent(
        context: Context,
        requestCode: Int,
        prayerKey: String,
        prayerName: String,
        soundType: Int
    ): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            putExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY, prayerKey)
            putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanPlaybackService.EXTRA_SOUND_TYPE, soundType)
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }
}
