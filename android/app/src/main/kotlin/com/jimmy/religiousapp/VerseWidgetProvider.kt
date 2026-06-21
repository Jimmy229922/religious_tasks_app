package com.jimmy.religiousapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class VerseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.verse_widget)
            
            views.setTextViewText(R.id.verse_text, widgetData.getString("verse_text", "فَاذْكُرُونِي أَذْكُرْكُمْ"))
            views.setTextViewText(R.id.verse_source, widgetData.getString("verse_source", "سورة البقرة"))

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
