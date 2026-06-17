package com.jimmy.religiousapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
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
                        val soundType = call.argument<Int>("soundType") ?: 0
                        val moazzenId = call.argument<String>("moazzenId") ?: "default"

                        if (requestCode == null || prayerKey == null || prayerName == null || timeMillis == null) {
                            result.error("INVALID_ARGS", "Missing native adhan schedule arguments", null)
                            return@setMethodCallHandler
                        }

                        NativeAdhanScheduler.schedule(this, requestCode, prayerKey, prayerName, timeMillis, soundType, moazzenId)
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
                        val soundType = call.argument<Int>("soundType") ?: 0
                        val moazzenId = call.argument<String>("moazzenId") ?: "default"
                        
                        val intent = Intent(this, AdhanPlaybackService::class.java).apply {
                            putExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY, prayerKey)
                            putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, prayerName)
                            putExtra(AdhanPlaybackService.EXTRA_SOUND_TYPE, soundType)
                            putExtra(AdhanPlaybackService.EXTRA_MOAZZEN_ID, moazzenId)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
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
