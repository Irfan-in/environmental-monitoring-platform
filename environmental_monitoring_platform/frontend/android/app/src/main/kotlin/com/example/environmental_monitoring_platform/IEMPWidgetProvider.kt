package com.example.environmental_monitoring_platform

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class IEMPWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        const val PREFS_NAME = "IEMPWidgetPrefs"
        const val KEY_INDOOR_TEMP = "indoor_temp"
        const val KEY_OUTDOOR_TEMP = "outdoor_temp"
        const val KEY_HUMIDITY = "humidity"
        const val KEY_WEATHER_DESC = "weather_desc"
        const val KEY_LOCATION = "location"
        const val KEY_UPDATED = "updated"

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val indoorTemp = prefs.getString(KEY_INDOOR_TEMP, "30.2°") ?: "30.2°"
            val outdoorTemp = prefs.getString(KEY_OUTDOOR_TEMP, "24.1°") ?: "24.1°"
            val humidity = prefs.getString(KEY_HUMIDITY, "78%") ?: "78%"
            val weatherDesc = prefs.getString(KEY_WEATHER_DESC, "Live") ?: "Live"
            val location = prefs.getString(KEY_LOCATION, "Periya, Kerala") ?: "Periya, Kerala"
            val updated = prefs.getString(KEY_UPDATED, "• Live") ?: "• Live"

            val views = RemoteViews(context.packageName, R.layout.widget_iemp)
            views.setTextViewText(R.id.widget_indoor_temp, indoorTemp)
            views.setTextViewText(R.id.widget_outdoor_temp, outdoorTemp)
            views.setTextViewText(R.id.widget_humidity, humidity)
            views.setTextViewText(R.id.widget_weather_desc, weatherDesc)
            views.setTextViewText(R.id.widget_location, location)
            views.setTextViewText(R.id.widget_updated, updated)

            // Tapping opens the app
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, IEMPWidgetProvider::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (widgetIds != null && widgetIds.isNotEmpty()) {
                for (id in widgetIds) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            }
        }
    }
}
