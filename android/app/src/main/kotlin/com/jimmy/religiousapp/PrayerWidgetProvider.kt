package com.jimmy.religiousapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
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
            
            // Current / Next Prayer Data
            views.setTextViewText(R.id.prayer_name, widgetData.getString("prayer_name", "--"))
            views.setTextViewText(R.id.prayer_time, widgetData.getString("prayer_time", "00:00"))
            views.setTextViewText(R.id.remaining_time, widgetData.getString("remaining_time", "--"))
            
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
            val highlight = Color.parseColor("#33FFFFFF") // Soft white highlight
            
            views.setInt(R.id.fajr_container, "setBackgroundColor", transparent)
            views.setInt(R.id.dhuhr_container, "setBackgroundColor", transparent)
            views.setInt(R.id.asr_container, "setBackgroundColor", transparent)
            views.setInt(R.id.maghrib_container, "setBackgroundColor", transparent)
            views.setInt(R.id.isha_container, "setBackgroundColor", transparent)

            // Highlight next
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
