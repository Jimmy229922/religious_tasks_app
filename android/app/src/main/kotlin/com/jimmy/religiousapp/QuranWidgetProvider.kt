package com.jimmy.religiousapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class QuranWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.quran_widget)
            
            views.setTextViewText(R.id.last_surah_text, widgetData.getString("last_surah", "الفاتحة"))
            val ayah = widgetData.getString("last_ayah", "1")
            views.setTextViewText(R.id.last_ayah_text, "آية $ayah")

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
