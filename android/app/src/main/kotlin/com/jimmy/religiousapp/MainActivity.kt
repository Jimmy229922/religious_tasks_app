package com.jimmy.religiousapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "religious_tasks_app/native_adhan")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "schedule" -> {
                        val requestCode = call.argument<Int>("requestCode")
                        val prayerKey = call.argument<String>("prayerKey")
                        val prayerName = call.argument<String>("prayerName")
                        val timeMillis = call.argument<Long>("timeMillis")

                        if (requestCode == null || prayerKey == null || prayerName == null || timeMillis == null) {
                            result.error("INVALID_ARGS", "Missing native adhan schedule arguments", null)
                            return@setMethodCallHandler
                        }

                        NativeAdhanScheduler.schedule(this, requestCode, prayerKey, prayerName, timeMillis)
                        result.success(null)
                    }
                    "cancel" -> {
                        val requestCode = call.argument<Int>("requestCode")
                        if (requestCode == null) {
                            result.error("INVALID_ARGS", "Missing native adhan cancel requestCode", null)
                            return@setMethodCallHandler
                        }

                        NativeAdhanScheduler.cancel(this, requestCode)
                        result.success(null)
                    }
                    "playNow" -> {
                        val prayerKey = call.argument<String>("prayerKey") ?: "fajr"
                        val prayerName = call.argument<String>("prayerName") ?: "الصلاة"
                        val intent = android.content.Intent(this, AdhanPlaybackService::class.java).apply {
                            putExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY, prayerKey)
                            putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, prayerName)
                        }

                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
