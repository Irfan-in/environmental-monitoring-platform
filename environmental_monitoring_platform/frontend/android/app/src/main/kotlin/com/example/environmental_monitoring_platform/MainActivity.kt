package com.example.environmental_monitoring_platform

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.environmental_monitoring_platform/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidgetData") {
                val indoorTemp = call.argument<String>("indoorTemp") ?: "--°"
                val outdoorTemp = call.argument<String>("outdoorTemp") ?: "--°"
                val humidity = call.argument<String>("humidity") ?: "--%"
                val weatherDesc = call.argument<String>("weatherDesc") ?: "Live"
                val location = call.argument<String>("location") ?: "Periya, Kerala"
                val updated = call.argument<String>("updated") ?: "• Live"

                val prefs = getSharedPreferences(IEMPWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit()
                    .putString(IEMPWidgetProvider.KEY_INDOOR_TEMP, indoorTemp)
                    .putString(IEMPWidgetProvider.KEY_OUTDOOR_TEMP, outdoorTemp)
                    .putString(IEMPWidgetProvider.KEY_HUMIDITY, humidity)
                    .putString(IEMPWidgetProvider.KEY_WEATHER_DESC, weatherDesc)
                    .putString(IEMPWidgetProvider.KEY_LOCATION, location)
                    .putString(IEMPWidgetProvider.KEY_UPDATED, updated)
                    .apply()

                IEMPWidgetProvider.updateAllWidgets(applicationContext)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
