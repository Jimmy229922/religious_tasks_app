package com.jimmy.religiousapp

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.TextView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant
import kotlin.random.Random

class LaunchActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var quoteView: TextView
    private lateinit var versionView: TextView
    private lateinit var quotes: Array<String>
    private var quoteIndex = 0

    private val rotateQuoteRunnable = object : Runnable {
        override fun run() {
            if (!::quoteView.isInitialized || quotes.isEmpty()) return
            quoteIndex = (quoteIndex + 1) % quotes.size
            quoteView.text = quotes[quoteIndex]
            handler.postDelayed(this, QUOTE_ROTATION_MS)
        }
    }

    private val launchMainRunnable = Runnable {
        startActivity(
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION),
        )
        overridePendingTransition(0, 0)
        finish()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_launch)

        quoteView = findViewById(R.id.splashQuote)
        versionView = findViewById(R.id.splashVersion)
        quotes = resources.getStringArray(R.array.splash_quotes)

        if (quotes.isNotEmpty()) {
            quoteIndex = Random.nextInt(quotes.size)
            quoteView.text = quotes[quoteIndex]
            handler.postDelayed(rotateQuoteRunnable, QUOTE_ROTATION_MS)
        }

        versionView.text = getString(R.string.splash_version_format, appVersionName())

        prewarmFlutterEngine()
        handler.postDelayed(launchMainRunnable, MINIMUM_LAUNCH_MS)
    }

    override fun onDestroy() {
        handler.removeCallbacks(rotateQuoteRunnable)
        handler.removeCallbacks(launchMainRunnable)
        super.onDestroy()
    }

    private fun prewarmFlutterEngine() {
        if (FlutterEngineCache.getInstance().get(CACHED_ENGINE_ID) != null) {
            return
        }

        val flutterEngine = FlutterEngine(this)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault(),
        )
        FlutterEngineCache.getInstance().put(CACHED_ENGINE_ID, flutterEngine)
    }

    private fun appVersionName(): String {
        val packageInfo = packageManager.getPackageInfo(packageName, 0)
        return packageInfo.versionName ?: ""
    }

    companion object {
        private const val MINIMUM_LAUNCH_MS = 1200L
        private const val QUOTE_ROTATION_MS = 1400L
    }
}
