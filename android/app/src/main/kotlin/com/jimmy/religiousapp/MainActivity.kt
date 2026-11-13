package com.jimmy.religiousapp

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.Activity
import android.accounts.AccountManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private var pendingAccountResult: MethodChannel.Result? = null

    companion object {
        private const val REQUEST_CODE_PICK_ACCOUNT = 1009
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.decorView.isForceDarkAllowed = false
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_PICK_ACCOUNT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val accountName = data.getStringExtra(AccountManager.KEY_ACCOUNT_NAME)
                pendingAccountResult?.success(accountName)
            } else {
                pendingAccountResult?.success(null)
            }
            pendingAccountResult = null
        }
    }

    @Suppress("DEPRECATION")
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "religious_tasks_app/native_adhan")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickGoogleAccount" -> {
                        try {
                            val intent = AccountManager.newChooseAccountIntent(
                                null, null, arrayOf("com.google"), false, null, null, null, null
                            )
                            pendingAccountResult = result
                            this@MainActivity.startActivityForResult(intent, REQUEST_CODE_PICK_ACCOUNT)
                        } catch (e: Exception) {
                            result.error("ACCOUNT_PICK_FAILED", e.message, null)
                        }
                    }
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

                        NativeAdhanScheduler.schedule(this@MainActivity, requestCode, prayerKey, prayerName, timeMillis, soundType, moazzenId)
                        result.success(null)
                    }
                    "cancel" -> {
                        val requestCode = call.argument<Int>("requestCode")
                        if (requestCode == null) {
                            result.error("INVALID_ARGS", "Missing native adhan cancel requestCode", null)
                            return@setMethodCallHandler
                        }

                        NativeAdhanScheduler.cancel(this@MainActivity, requestCode)
                        result.success(null)
                    }
                    "playNow" -> {
                        val prayerKey = call.argument<String>("prayerKey") ?: "fajr"
                        val prayerName = call.argument<String>("prayerName") ?: "الصلاة"
                        val soundType = call.argument<Int>("soundType") ?: 0
                        val moazzenId = call.argument<String>("moazzenId") ?: "default"

                        val intent = Intent(this@MainActivity, AdhanPlaybackService::class.java).apply {
                            putExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY, prayerKey)
                            putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, prayerName)
                            putExtra(AdhanPlaybackService.EXTRA_SOUND_TYPE, soundType)
                            putExtra(AdhanPlaybackService.EXTRA_MOAZZEN_ID, moazzenId)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            this@MainActivity.startForegroundService(intent)
                        } else {
                            this@MainActivity.startService(intent)
                        }
                        result.success(null)
                    }
                    "playSalawatNow" -> {
                        val intent = Intent(this@MainActivity, AdhanPlaybackService::class.java).apply {
                            putExtra(AdhanPlaybackService.EXTRA_PRAYER_KEY, "salawat")
                            putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, "الصلاة على النبي")
                            putExtra(AdhanPlaybackService.EXTRA_SOUND_TYPE, 99)
                            putExtra(AdhanPlaybackService.EXTRA_MOAZZEN_ID, "default")
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            this@MainActivity.startForegroundService(intent)
                        } else {
                            this@MainActivity.startService(intent)
                        }
                        result.success(null)
                    }
                    "bringToForeground" -> {
                        val intent = Intent(this@MainActivity, MainActivity::class.java)
                        intent.flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_NEW_TASK
                        this@MainActivity.startActivity(intent)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
