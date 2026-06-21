package com.jimmy.religiousapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.os.SystemClock
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.prayer_widget)
            
            // Interactive Data
            views.setTextViewText(R.id.location_name, widgetData.getString("location_name", "تحديد الموقع..."))
            views.setTextViewText(R.id.hijri_date, widgetData.getString("hijri_date", "--"))
            
            // Current / Next Prayer Data
            views.setTextViewText(R.id.prayer_name, widgetData.getString("prayer_name", "--"))
            views.setTextViewText(R.id.prayer_time, widgetData.getString("prayer_time", "00:00"))
            
            // Live Countdown (Chronometer)
            val nextTimestamp = widgetData.getLong("next_prayer_timestamp", 0)
            if (nextTimestamp > 0) {
                // Chronometer base is relative to SystemClock.elapsedRealtime()
                val remainingMillis = nextTimestamp - System.currentTimeMillis()
                views.setChronometerCountDown(R.id.remaining_time, true)
                views.setChronometer(R.id.remaining_time, SystemClock.elapsedRealtime() + remainingMillis, null, true)
            }

            // All Prayer Times
            val fajr = widgetData.getString("fajr_time", "--")
            val dhuhr = widgetData.getString("dhuhr_time", "--")
            val asr = widgetData.getString("asr_time", "--")
            val maghrib = widgetData.getString("maghrib_time", "--")
            val isha = widgetData.getString("isha_time", "--")
            val nextId = widgetData.getString("next_prayer_id", "")

            views.setTextViewText(R.id.fajr_time, fajr)
            views.setTextViewText(R.id.dhuhr_time, dhuhr)
            views.setTextViewText(R.id.asr_time, asr)
            views.setTextViewText(R.id.maghrib_time, maghrib)
            views.setTextViewText(R.id.isha_time, isha)

            // Reset backgrounds
            val transparent = Color.TRANSPARENT
            val highlight = Color.parseColor("#4DFFFFFF")
            
            views.setInt(R.id.fajr_container, "setBackgroundColor", transparent)
            views.setInt(R.id.dhuhr_container, "setBackgroundColor", transparent)
            views.setInt(R.id.asr_container, "setBackgroundColor", transparent)
            views.setInt(R.id.maghrib_container, "setBackgroundColor", transparent)
            views.setInt(R.id.isha_container, "setBackgroundColor", transparent)

            when (nextId?.lowercase()) {
                "fajr" -> views.setInt(R.id.fajr_container, "setBackgroundColor", highlight)
                "dhuhr" -> views.setInt(R.id.dhuhr_container, "setBackgroundColor", highlight)
                "asr" -> views.setInt(R.id.asr_container, "setBackgroundColor", highlight)
                "maghrib" -> views.setInt(R.id.maghrib_container, "setBackgroundColor", highlight)
                "isha" -> views.setInt(R.id.isha_container, "setBackgroundColor", highlight)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
