package com.jimmy.religiousapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
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
            views.setTextViewText(R.id.prayer_name, widgetData.getString("prayer_name", "--"))
            views.setTextViewText(R.id.prayer_time, widgetData.getString("prayer_time", "00:00"))
            views.setTextViewText(R.id.remaining_time, widgetData.getString("remaining_time", "--"))
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
