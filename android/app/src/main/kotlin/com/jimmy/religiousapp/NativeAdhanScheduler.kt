package com.jimmy.religiousapp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject

object NativeAdhanScheduler {
    private const val PREFS_NAME = "NativeScheduledAlarms"
    private const val KEY_ALARMS_MAP = "alarms_map_v1"

    fun schedule(
        context: Context,
        requestCode: Int,
        prayerKey: String,
        prayerName: String,
        timeMillis: Long,
        soundType: Int,
        moazzenId: String
    ) {
        saveAlarmRecord(context, requestCode, prayerKey, prayerName, timeMillis, soundType, moazzenId)
        scheduleInternal(context, requestCode, prayerKey, prayerName, timeMillis, soundType, moazzenId)
    }

    private fun scheduleInternal(
        context: Context,
        requestCode: Int,
        prayerKey: String,
        prayerName: String,
        timeMillis: Long,
        soundType: Int,
        moazzenId: String
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntent(context, requestCode, prayerKey, prayerName, soundType, moazzenId)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    val info = AlarmManager.AlarmClockInfo(timeMillis, pendingIntent)
                    alarmManager.setAlarmClock(info, pendingIntent)
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            } else {
                val info = AlarmManager.AlarmClockInfo(timeMillis, pendingIntent)
                alarmManager.setAlarmClock(info, pendingIntent)
            }
        } catch (_: Exception) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            }
        }
    }

    fun cancel(context: Context, requestCode: Int) {
        removeAlarmRecord(context, requestCode)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.cancel(pendingIntent(context, requestCode, "", "", 0, "default"))
    }

    fun reschedulePersistedAlarms(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_ALARMS_MAP, null) ?: return
        val now = System.currentTimeMillis()
        try {
            val map = JSONObject(raw)
            val updated = JSONObject()
            val keys = map.keys()
            while (keys.hasNext()) {
                val reqKey = keys.next()
                val reqCode = reqKey.toIntOrNull() ?: continue
                val obj = map.optJSONObject(reqKey) ?: continue
                val timeMillis = obj.optLong("timeMillis", 0L)
                if (timeMillis <= now + 1000L) continue

                val prayerKey = obj.optString("prayerKey", "fajr")
                val prayerName = obj.optString("prayerName", "الصلاة")
                val soundType = obj.optInt("soundType", 0)
                val moazzenId = obj.optString("moazzenId", "default")

                scheduleInternal(context, reqCode, prayerKey, prayerName, timeMillis, soundType, moazzenId)
                updated.put(reqKey, obj)
            }
            prefs.edit().putString(KEY_ALARMS_MAP, updated.toString()).apply()
        } catch (_: Exception) {
        }
    }

    private fun saveAlarmRecord(
        context: Context,
        requestCode: Int,
        prayerKey: String,
        prayerName: String,
        timeMillis: Long,
        soundType: Int,
        moazzenId: String
    ) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_ALARMS_MAP, null)
            val map = if (raw != null) JSONObject(raw) else JSONObject()

            val now = System.currentTimeMillis()
            val cleaned = JSONObject()
            val existingKeys = map.keys()
            while (existingKeys.hasNext()) {
                val k = existingKeys.next()
                val item = map.optJSONObject(k) ?: continue
                if (item.optLong("timeMillis", 0L) > now) {
                    cleaned.put(k, item)
                }
            }

            val entry = JSONObject().apply {
                put("prayerKey", prayerKey)
                put("prayerName", prayerName)
                put("timeMillis", timeMillis)
                put("soundType", soundType)
                put("moazzenId", moazzenId)
            }
            cleaned.put(requestCode.toString(), entry)
            prefs.edit().putString(KEY_ALARMS_MAP, cleaned.toString()).apply()
        } catch (_: Exception) {
        }
    }

    private fun removeAlarmRecord(context: Context, requestCode: Int) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_ALARMS_MAP, null) ?: return
            val map = JSONObject(raw)
            map.remove(requestCode.toString())
            prefs.edit().putString(KEY_ALARMS_MAP, map.toString()).apply()
        } catch (_: Exception) {
        }
    }

    private fun pendingIntent(
        context: Context,
        requestCode: Int,
        prayerKey: String,
        prayerName: String,
        soundType: Int,
        moazzenId: String
    ): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            putExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY, prayerKey)
            putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, prayerName)
            putExtra(AdhanPlaybackService.EXTRA_SOUND_TYPE, soundType)
            putExtra(AdhanPlaybackService.EXTRA_MOAZZEN_ID, moazzenId)
        }

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }
}
