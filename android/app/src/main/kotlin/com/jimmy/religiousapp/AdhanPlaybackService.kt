package com.jimmy.religiousapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat

@Suppress("NewApi")
class AdhanPlaybackService : Service() {
    private var salawatPlayer: MediaPlayer? = null
    private var adhanPlayer: MediaPlayer? = null
    private var salawatWasPausedForAdhan: Boolean = false
    private var salawatPendingAfterAdhan: Boolean = false
    private var activeAdhanKey: String = "fajr"
    private var activeAdhanName: String = "الصلاة"
    private val fadeHandler = Handler(Looper.getMainLooper())
    private var salawatFadeRunnable: Runnable? = null
    private lateinit var audioManager: AudioManager
    private var audioFocusRequest: AudioFocusRequest? = null
    private var playbackStartedElapsedMs: Long = 0L
    private var isVolumeReceiverRegistered: Boolean = false

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change == AudioManager.AUDIOFOCUS_LOSS ||
            change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT
        ) {
            stopAll()
            stopForegroundAndRemove()
            stopSelf()
        }
    }

    private val volumeChangeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != VOLUME_CHANGED_ACTION) return
            val elapsed = SystemClock.elapsedRealtime() - playbackStartedElapsedMs
            if (elapsed < 250L) return

            val streamType = intent.getIntExtra(EXTRA_VOLUME_STREAM_TYPE, -1)
            if (streamType != AudioManager.STREAM_MUSIC &&
                streamType != AudioManager.STREAM_ALARM &&
                streamType != AudioManager.STREAM_RING
            ) {
                return
            }

            val newVol = intent.getIntExtra(EXTRA_VOLUME_STREAM_VALUE, -1)
            val prevVol = intent.getIntExtra(EXTRA_PREV_VOLUME_STREAM_VALUE, -1)
            if (prevVol != -1 && newVol == prevVol) return

            handleVolumeStopRequest()
        }
    }

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        ensureChannels(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP_ADHAN) {
            stopAll()
            stopForegroundAndRemove()
            stopSelf()
            return START_NOT_STICKY
        }

        if (intent?.action == ACTION_VOLUME_STOP) {
            handleVolumeStopRequest()
            return START_NOT_STICKY
        }

        val prayerKey = intent?.getStringExtra(EXTRA_PRAYER_KEY) ?: "fajr"
        val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: "الصلاة"
        val soundType = intent?.getIntExtra(EXTRA_SOUND_TYPE, 0) ?: 0 // 0: none, 1: short, 2: full, 99: salawat
        val moazzenId = intent?.getStringExtra(EXTRA_MOAZZEN_ID) ?: "default"
        val isSalawat = (soundType == 99 || prayerKey.lowercase() == "salawat")

        if (soundType == 0) {
            postAlertNotification(this, prayerKey, prayerName, playSound = false)
            if (adhanPlayer?.isPlaying != true && salawatPlayer?.isPlaying != true) {
                stopForegroundAndRemove()
                stopSelf()
            }
            return START_NOT_STICKY
        }

        if (isSalawat && adhanPlayer?.isPlaying == true) {
            // Keep active Adhan foreground notification intact, postpone Salawat until Adhan completes
            startForeground(
                FOREGROUND_NOTIFICATION_ID,
                buildPlayingNotification(this, activeAdhanName, activeAdhanKey)
            )
            salawatPendingAfterAdhan = true
            return START_NOT_STICKY
        }

        if (!isSalawat) {
            activeAdhanKey = prayerKey
            activeAdhanName = prayerName
        }

        startForeground(
            FOREGROUND_NOTIFICATION_ID,
            buildPlayingNotification(this, prayerName, prayerKey)
        )

        requestAudioFocus()
        registerVolumeReceiver()

        if (isSalawat) {
            playSalawat()
        } else {
            playAdhan(prayerKey, soundType, moazzenId)
        }

        return START_NOT_STICKY
    }

    private fun handleVolumeStopRequest() {
        val adhanPlaying = isAdhanActive || (adhanPlayer?.isPlaying == true)
        val salawatPlaying = isSalawatActive || (salawatPlayer?.isPlaying == true)

        if (adhanPlaying && isStopAdhanOnVolumeEnabled(this)) {
            Log.d("AdhanService", "Volume key pressed -> stopping Adhan.")
            stopAll()
            stopForegroundAndRemove()
            stopSelf()
        } else if (!adhanPlaying && salawatPlaying && isStopSalawatOnVolumeEnabled(this)) {
            Log.d("AdhanService", "Volume key pressed -> stopping Salawat.")
            stopAll()
            stopForegroundAndRemove()
            stopSelf()
        }
    }

    @Suppress("UnspecifiedRegisterReceiverFlag")
    private fun registerVolumeReceiver() {
        if (isVolumeReceiverRegistered) return
        try {
            val filter = IntentFilter(VOLUME_CHANGED_ACTION)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(volumeChangeReceiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                registerReceiver(volumeChangeReceiver, filter)
            }
            isVolumeReceiverRegistered = true
        } catch (e: Exception) {
            Log.e("AdhanService", "Failed to register volume receiver: ${e.message}")
        }
    }

    private fun unregisterVolumeReceiver() {
        if (!isVolumeReceiverRegistered) return
        try {
            unregisterReceiver(volumeChangeReceiver)
        } catch (_: Exception) {
        } finally {
            isVolumeReceiverRegistered = false
        }
    }

    private fun stopForegroundAndRemove() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {
        }
    }

    private fun stopAll() {
        cancelSalawatFadeIn()
        unregisterVolumeReceiver()
        salawatWasPausedForAdhan = false
        salawatPendingAfterAdhan = false
        isAdhanActive = false
        isSalawatActive = false

        val sPlayer: MediaPlayer? = salawatPlayer
        if (sPlayer != null) {
            try {
                if (sPlayer.isPlaying) {
                    sPlayer.stop()
                }
                sPlayer.release()
            } catch (_: Exception) {}
        }
        salawatPlayer = null

        val aPlayer: MediaPlayer? = adhanPlayer
        if (aPlayer != null) {
            try {
                if (aPlayer.isPlaying) {
                    aPlayer.stop()
                }
                aPlayer.release()
            } catch (_: Exception) {}
        }
        adhanPlayer = null
        abandonAudioFocus()
    }

    private fun requestAudioFocus(): Boolean {
        val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setOnAudioFocusChangeListener(audioFocusChangeListener)
                .build()
            audioFocusRequest = request
            audioManager.requestAudioFocus(request)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(
                audioFocusChangeListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN_TRANSIENT
            )
        }
        return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
    }

    private fun abandonAudioFocus() {
        if (!::audioManager.isInitialized) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(audioFocusChangeListener)
        }
    }

    override fun onDestroy() {
        stopAll()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun cancelSalawatFadeIn() {
        salawatFadeRunnable?.let { fadeHandler.removeCallbacks(it) }
        salawatFadeRunnable = null
    }

    private fun startSalawatFadeIn(player: MediaPlayer) {
        cancelSalawatFadeIn()
        val totalSteps = 30
        val stepDelayMs = 100L
        var currentStep = 0

        val runnable = object : Runnable {
            override fun run() {
                if (salawatPlayer !== player) {
                    salawatFadeRunnable = null
                    return
                }
                currentStep++
                val progress = (currentStep.toFloat() / totalSteps).coerceIn(0f, 1f)
                val volume = 0.05f + 0.95f * (progress * progress)
                try {
                    player.setVolume(volume, volume)
                } catch (_: Exception) {
                    salawatFadeRunnable = null
                    return
                }
                if (currentStep < totalSteps) {
                    fadeHandler.postDelayed(this, stepDelayMs)
                } else {
                    salawatFadeRunnable = null
                }
            }
        }
        salawatFadeRunnable = runnable
        fadeHandler.postDelayed(runnable, stepDelayMs)
    }

    private fun playSalawat() {
        val aPlayer: MediaPlayer? = adhanPlayer
        if (aPlayer != null && aPlayer.isPlaying) {
            Log.d("AdhanService", "Adhan is currently playing. Postponing Salawat until Adhan completes.")
            salawatPendingAfterAdhan = true
            return
        }

        val sPlayer: MediaPlayer? = salawatPlayer
        if (sPlayer != null && sPlayer.isPlaying) {
            Log.d("AdhanService", "Salawat is already playing, keeping it going.")
            isSalawatActive = true
            return
        }

        try {
            val descriptor = resources.openRawResourceFd(R.raw.salawat_sound)
            if (descriptor == null) {
                playSystemSalawatSound()
                return
            }
            cancelSalawatFadeIn()
            salawatPlayer?.release()
            salawatPlayer = MediaPlayer().apply {
                val attributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
                setAudioAttributes(attributes)
                setVolume(0.05f, 0.05f)

                setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                descriptor.close()
                setOnCompletionListener {
                    cancelSalawatFadeIn()
                    salawatPlayer?.release()
                    salawatPlayer = null
                    isSalawatActive = false
                    onSalawatAudioFinished()
                }
                setOnErrorListener { player, _, _ ->
                    cancelSalawatFadeIn()
                    player.release()
                    salawatPlayer = null
                    isSalawatActive = false
                    playSystemSalawatSound()
                    true
                }
                prepare()
                playbackStartedElapsedMs = SystemClock.elapsedRealtime()
                isSalawatActive = true
                start()
                startSalawatFadeIn(this)
            }
        } catch (_: Exception) {
            isSalawatActive = false
            Log.e("AdhanService", "Error playing salawat audio, falling back to system notification sound")
            playSystemSalawatSound()
        }
    }

    private fun playSystemSalawatSound() {
        try {
            val systemUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            if (systemUri == null) {
                isSalawatActive = false
                onSalawatAudioFinished()
                return
            }
            cancelSalawatFadeIn()
            salawatPlayer?.release()
            salawatPlayer = MediaPlayer().apply {
                val attributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
                setAudioAttributes(attributes)
                setVolume(0.05f, 0.05f)
                setDataSource(applicationContext, systemUri)
                setOnCompletionListener {
                    cancelSalawatFadeIn()
                    salawatPlayer?.release()
                    salawatPlayer = null
                    isSalawatActive = false
                    onSalawatAudioFinished()
                }
                setOnErrorListener { player, _, _ ->
                    cancelSalawatFadeIn()
                    player.release()
                    salawatPlayer = null
                    isSalawatActive = false
                    onSalawatAudioFinished()
                    true
                }
                prepare()
                playbackStartedElapsedMs = SystemClock.elapsedRealtime()
                isSalawatActive = true
                start()
                startSalawatFadeIn(this)
            }
        } catch (e: Exception) {
            isSalawatActive = false
            Log.e("AdhanService", "Error playing system salawat audio: ${e.message}")
            onSalawatAudioFinished()
        }
    }

    private fun onSalawatAudioFinished() {
        // Keep a clean persistent Salawat notification visible after the short audio finishes
        postAlertNotification(this, "salawat", "الصلاة على النبي", playSound = false)
        val activeAdhan: MediaPlayer? = adhanPlayer
        if (activeAdhan == null || !activeAdhan.isPlaying) {
            stopForegroundAndRemove()
            stopSelf()
        }
    }

    private fun playAdhan(prayerKey: String, soundType: Int, moazzenId: String) {
        val sPlayer: MediaPlayer? = salawatPlayer
        if (sPlayer != null && sPlayer.isPlaying) {
            try {
                cancelSalawatFadeIn()
                sPlayer.pause()
                sPlayer.setVolume(1.0f, 1.0f)
                salawatWasPausedForAdhan = true
                isSalawatActive = false
                Log.d("AdhanService", "Salawat paused for Adhan.")
            } catch (_: Exception) {
                Log.e("AdhanService", "Failed to pause salawat")
            }
        }

        if (moazzenId == "system") {
            playSystemAdhanSound()
            return
        }

        val soundResId = if (soundType == 1) {
            R.raw.prayer_reminder
        } else {
            getAdhanResource(prayerKey, moazzenId)
        }

        if (soundResId == 0) {
            playSystemAdhanSound()
            return
        }

        try {
            val descriptor = resources.openRawResourceFd(soundResId)
            if (descriptor == null) {
                playSystemAdhanSound()
                return
            }
            adhanPlayer?.release()
            adhanPlayer = MediaPlayer().apply {
                val attributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
                setAudioAttributes(attributes)

                setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                descriptor.close()

                setOnCompletionListener {
                    adhanPlayer?.release()
                    adhanPlayer = null
                    isAdhanActive = false
                    onAdhanAudioFinished()
                }
                setOnErrorListener { _, _, _ ->
                    adhanPlayer = null
                    isAdhanActive = false
                    playSystemAdhanSound()
                    true
                }
                prepare()
                playbackStartedElapsedMs = SystemClock.elapsedRealtime()
                isAdhanActive = true
                start()
            }
        } catch (_: Exception) {
            isAdhanActive = false
            Log.e("AdhanService", "Error playing adhan raw audio, falling back to system sound")
            playSystemAdhanSound()
        }
    }

    private fun playSystemAdhanSound() {
        try {
            val systemUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            if (systemUri == null) {
                isAdhanActive = false
                onAdhanAudioFinished()
                return
            }
            adhanPlayer?.release()
            adhanPlayer = MediaPlayer().apply {
                val attributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                setAudioAttributes(attributes)
                setDataSource(applicationContext, systemUri)
                setOnCompletionListener {
                    adhanPlayer?.release()
                    adhanPlayer = null
                    isAdhanActive = false
                    onAdhanAudioFinished()
                }
                setOnErrorListener { _, _, _ ->
                    adhanPlayer = null
                    isAdhanActive = false
                    onAdhanAudioFinished()
                    true
                }
                prepare()
                playbackStartedElapsedMs = SystemClock.elapsedRealtime()
                isAdhanActive = true
                start()
            }
        } catch (e: Exception) {
            isAdhanActive = false
            Log.e("AdhanService", "Error playing system audio: ${e.message}")
            onAdhanAudioFinished()
        }
    }

    private fun onAdhanAudioFinished() {
        // Persist a clean Adhan notification so the user always sees it even after Adhan ends
        postAlertNotification(this, activeAdhanKey, activeAdhanName, playSound = false)

        if (salawatWasPausedForAdhan) {
            val salawat: MediaPlayer? = salawatPlayer
            if (salawat != null) {
                try {
                    startForeground(
                        FOREGROUND_NOTIFICATION_ID,
                        buildPlayingNotification(this, "الصلاة على النبي", "salawat")
                    )
                    playbackStartedElapsedMs = SystemClock.elapsedRealtime()
                    isSalawatActive = true
                    salawat.start()
                    salawatWasPausedForAdhan = false
                    Log.d("AdhanService", "Salawat resumed after Adhan finished.")
                } catch (_: Exception) {
                    isSalawatActive = false
                    Log.e("AdhanService", "Failed to resume salawat after Adhan")
                    stopForegroundAndRemove()
                    stopSelf()
                }
            } else {
                stopForegroundAndRemove()
                stopSelf()
            }
        } else if (salawatPendingAfterAdhan) {
            salawatPendingAfterAdhan = false
            Log.d("AdhanService", "Adhan completed, starting pending Salawat.")
            startForeground(
                FOREGROUND_NOTIFICATION_ID,
                buildPlayingNotification(this, "الصلاة على النبي", "salawat")
            )
            playSalawat()
        } else {
            stopForegroundAndRemove()
            stopSelf()
        }
    }

    private fun getAdhanResource(prayerKey: String, moazzenId: String): Int {
        if (moazzenId == "system") return 0
        val isFajr = prayerKey.lowercase() == "fajr"
        return when (moazzenId) {
            "afasy" -> if (isFajr) R.raw.afasy_fajr else R.raw.afasy_others
            "basit" -> if (isFajr) R.raw.basit_fajr else R.raw.basit_others
            "minshawi" -> if (isFajr) R.raw.minshawi_fajr else R.raw.minshawi_others
            "muaiqly" -> if (isFajr) R.raw.muaiqly_fajr else R.raw.muaiqly_others
            "dosari" -> if (isFajr) R.raw.dosari_fajr else R.raw.dosari_others
            else -> if (isFajr) R.raw.default_fajr else R.raw.default_others
        }
    }

    companion object {
        const val EXTRA_PRAYER_KEY = "prayer_key"
        const val EXTRA_PRAYER_NAME = "prayer_name"
        const val EXTRA_SOUND_TYPE = "sound_type"
        const val EXTRA_MOAZZEN_ID = "moazzen_id"
        const val ACTION_STOP_ADHAN = "com.jimmy.religiousapp.STOP_ADHAN"
        const val ACTION_VOLUME_STOP = "com.jimmy.religiousapp.VOLUME_STOP"
        private const val CHANNEL_ID = "native_adhan_playback_v3"
        private const val FALLBACK_ADHAN_CHANNEL_ID = "native_adhan_fallback_v1"
        private const val FALLBACK_SALAWAT_CHANNEL_ID = "salawat_notifications_v2"
        private const val FOREGROUND_NOTIFICATION_ID = 9001
        private const val ALERT_ID_ADHAN = 9011
        private const val ALERT_ID_SALAWAT = 9012

        private const val VOLUME_CHANGED_ACTION = "android.media.VOLUME_CHANGED_ACTION"
        private const val EXTRA_VOLUME_STREAM_TYPE = "android.media.EXTRA_VOLUME_STREAM_TYPE"
        private const val EXTRA_VOLUME_STREAM_VALUE = "android.media.EXTRA_VOLUME_STREAM_VALUE"
        private const val EXTRA_PREV_VOLUME_STREAM_VALUE = "android.media.EXTRA_PREV_VOLUME_STREAM_VALUE"

        private const val NATIVE_PREFS_NAME = "AdhanNativeSettings"
        private const val KEY_NATIVE_STOP_ADHAN = "stop_adhan_on_volume_btn"
        private const val KEY_NATIVE_STOP_SALAWAT = "stop_salawat_on_volume_btn"
        private const val FLUTTER_PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_FLUTTER_STOP_ADHAN = "flutter.stop_adhan_on_volume_btn_v1"
        private const val KEY_FLUTTER_STOP_SALAWAT = "flutter.stop_salawat_on_volume_btn_v1"

        @Volatile
        var isAdhanActive: Boolean = false

        @Volatile
        var isSalawatActive: Boolean = false

        fun ensureChannels(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val playbackChannel = NotificationChannel(
                CHANNEL_ID,
                "تنبيهات الأذان والتسبيح",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                setSound(null, null)
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(playbackChannel)

            val adhanFallbackChannel = NotificationChannel(
                FALLBACK_ADHAN_CHANNEL_ID,
                "تنبيهات الأذان الاحتياطية",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                setSound(
                    alarmSound,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_EVENT)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(adhanFallbackChannel)

            val salawatUri = Uri.parse("android.resource://${context.packageName}/${R.raw.salawat_sound}")
            val salawatFallbackChannel = NotificationChannel(
                FALLBACK_SALAWAT_CHANNEL_ID,
                "تنبيهات الصلاة على النبي",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "تنبيهات وصوت الصلاة على النبي ﷺ"
                setSound(
                    salawatUri,
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(salawatFallbackChannel)
        }

        private fun isSalawatEvent(prayerName: String, prayerKey: String): Boolean {
            return prayerName.contains("النبي") ||
                prayerName.contains("صل") ||
                prayerKey.lowercase() == "salawat"
        }

        private fun buildLaunchAppPendingIntent(context: Context, requestCode: Int): PendingIntent {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            return PendingIntent.getActivity(context, requestCode, launchIntent, flags)
        }

        fun buildPlayingNotification(
            context: Context,
            prayerName: String,
            prayerKey: String
        ): Notification {
            ensureChannels(context)

            val stopIntent = Intent(context, AdhanPlaybackService::class.java).apply {
                action = ACTION_STOP_ADHAN
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            val stopPendingIntent = PendingIntent.getService(context, 0, stopIntent, flags)

            val isSalawat = isSalawatEvent(prayerName, prayerKey)
            val contentTitle = if (isSalawat) "صَلِّ عَلَى مُحَمَّدٍ ﷺ" else "حَانَ الْآنَ مَوْعِدُ صَلَاةِ $prayerName"
            val contentText = if (isSalawat) "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ 🤍" else "أَقِمِ الصَّلَاةَ لِذِكْرِي"

            return NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(contentTitle)
                .setContentText(contentText)
                .setStyle(NotificationCompat.BigTextStyle().bigText(contentText))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(if (isSalawat) NotificationCompat.CATEGORY_REMINDER else NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setContentIntent(buildLaunchAppPendingIntent(context, if (isSalawat) 9102 else 9101))
                .setOngoing(false)
                .setDeleteIntent(stopPendingIntent)
                .addAction(android.R.drawable.ic_menu_close_clear_cancel, "إيقاف الصوت", stopPendingIntent)
                .setSilent(true)
                .build()
        }

        fun postAlertNotification(
            context: Context,
            prayerKey: String,
            prayerName: String,
            playSound: Boolean
        ) {
            try {
                ensureChannels(context)
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                val isSalawat = isSalawatEvent(prayerName, prayerKey)
                val channelId = when {
                    !playSound -> CHANNEL_ID
                    isSalawat -> FALLBACK_SALAWAT_CHANNEL_ID
                    else -> FALLBACK_ADHAN_CHANNEL_ID
                }
                val contentTitle = if (isSalawat) "صَلِّ عَلَى مُحَمَّدٍ ﷺ" else "حَانَ الْآنَ مَوْعِدُ صَلَاةِ $prayerName"
                val contentText = if (isSalawat) "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ 🤍" else "أَقِمِ الصَّلَاةَ لِذِكْرِي"
                val notificationId = if (isSalawat) ALERT_ID_SALAWAT else ALERT_ID_ADHAN

                val builder = NotificationCompat.Builder(context, channelId)
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setContentTitle(contentTitle)
                    .setContentText(contentText)
                    .setStyle(NotificationCompat.BigTextStyle().bigText(contentText))
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setCategory(if (isSalawat) NotificationCompat.CATEGORY_REMINDER else NotificationCompat.CATEGORY_ALARM)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setContentIntent(buildLaunchAppPendingIntent(context, notificationId))
                    .setAutoCancel(true)

                if (!playSound) {
                    builder.setSilent(true)
                }

                manager.notify(notificationId, builder.build())
            } catch (e: SecurityException) {
                Log.w("AdhanService", "Missing POST_NOTIFICATIONS permission: ${e.message}")
            } catch (e: Exception) {
                Log.e("AdhanService", "Failed to post alert notification: ${e.message}")
            }
        }

        fun saveVolumeStopSettings(
            context: Context,
            stopAdhan: Boolean?,
            stopSalawat: Boolean?
        ) {
            val prefs = context.getSharedPreferences(NATIVE_PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                if (stopAdhan != null) putBoolean(KEY_NATIVE_STOP_ADHAN, stopAdhan)
                if (stopSalawat != null) putBoolean(KEY_NATIVE_STOP_SALAWAT, stopSalawat)
            }.apply()
        }

        fun isStopAdhanOnVolumeEnabled(context: Context): Boolean {
            val nativePrefs = context.getSharedPreferences(NATIVE_PREFS_NAME, Context.MODE_PRIVATE)
            if (nativePrefs.contains(KEY_NATIVE_STOP_ADHAN)) {
                return nativePrefs.getBoolean(KEY_NATIVE_STOP_ADHAN, false)
            }
            val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            return flutterPrefs.getBoolean(KEY_FLUTTER_STOP_ADHAN, false)
        }

        fun isStopSalawatOnVolumeEnabled(context: Context): Boolean {
            val nativePrefs = context.getSharedPreferences(NATIVE_PREFS_NAME, Context.MODE_PRIVATE)
            if (nativePrefs.contains(KEY_NATIVE_STOP_SALAWAT)) {
                return nativePrefs.getBoolean(KEY_NATIVE_STOP_SALAWAT, false)
            }
            val flutterPrefs = context.getSharedPreferences(FLUTTER_PREFS_NAME, Context.MODE_PRIVATE)
            return flutterPrefs.getBoolean(KEY_FLUTTER_STOP_SALAWAT, false)
        }

        fun shouldStopOnVolumeKey(context: Context): Boolean {
            return (isAdhanActive && isStopAdhanOnVolumeEnabled(context)) ||
                (!isAdhanActive && isSalawatActive && isStopSalawatOnVolumeEnabled(context))
        }
    }
}
