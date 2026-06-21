package com.jimmy.religiousapp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class DhikrWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.dhikr_widget)
            
            val completed = widgetData.getInt("completed_tasks", 0)
            val total = widgetData.getInt("total_tasks", 0)
            val progress = if (total > 0) (completed * 100) / total else 0
            
            views.setTextViewText(R.id.dhikr_progress_text, "$completed / $total")
            views.setProgressBar(R.id.dhikr_progress_bar, 100, progress, false)
            
            val status = when {
                progress >= 100 -> "تم بنجاح! 🎉"
                progress > 50 -> "أوشكت على الانتهاء"
                progress > 0 -> "بداية جيدة، استمر"
                else -> "استعن بالله وابدأ"
            }
            views.setTextViewText(R.id.dhikr_status, status)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
