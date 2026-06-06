package com.softsheeply.shiftrest

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class ShiftRestWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val widgetData = HomeWidgetPlugin.getData(context)

        val shiftLabel = widgetData.getString("shift_label", "Open ShiftRest") ?: "Open ShiftRest"
        val sleepWindow = widgetData.getString("sleep_window", "No plan yet") ?: "No plan yet"
        val caffeine = widgetData.getString("caffeine_cutoff", "") ?: ""
        val updated = widgetData.getString("last_updated", "") ?: ""

        val views = RemoteViews(context.packageName, R.layout.shiftrest_widget)
        views.setTextViewText(R.id.widget_shift_label, shiftLabel)
        views.setTextViewText(R.id.widget_sleep_window, sleepWindow)
        views.setTextViewText(R.id.widget_caffeine, if (caffeine.isNotEmpty()) "☕ $caffeine" else "")
        views.setTextViewText(R.id.widget_updated, if (updated.isNotEmpty()) "Updated $updated" else "")

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
