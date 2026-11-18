package com.jimmy.religiousapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import android.util.Log

@Suppress("NewApi")
class AdhanPlaybackService : Service() {
    private var salawatPlayer: MediaPlayer? = null
    private var adhanPlayer: MediaPlayer? = null
    private var salawatWasPausedForAdhan: Boolean = false
    private var salawatPendingAfterAdhan: Boolean = false
    private val fadeHandler = Handler(Looper.getMainLooper())
    private var salawatFadeRunnable: Runnable? = null
    private lateinit var audioManager: AudioManager
    private var audioFocusRequest: AudioFocusRequest? = null
    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change == AudioManager.AUDIOFOCUS_LOSS ||
            change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT
        ) {
            stopAll()
            stopSelf()
        }
    }

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP_ADHAN) {
            stopAll()
            stopSelf()
            return START_NOT_STICKY
        }

        val prayerKey = intent?.getStringExtra(EXTRA_PRAYER_KEY) ?: "fajr"
        val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: "الصلاة"
        val soundType = intent?.getIntExtra(EXTRA_SOUND_TYPE, 0) ?: 0 // 0: none, 1: short, 2: full, 99: salawat
        val moazzenId = intent?.getStringExtra(EXTRA_MOAZZEN_ID) ?: "default"

        startForeground(NOTIFICATION_ID, buildNotification(prayerName, prayerKey))

        if (soundType == 0) {
            // Keep the prayer notification visible, but do not leave an idle
            // foreground service running when the user selected silent mode.
            stopForeground(STOP_FOREGROUND_DETACH)
            stopSelf()
            return START_NOT_STICKY
        }

        // Request audio focus, but never cancel playback if focus request is delayed or rejected
        requestAudioFocus()

        val isSalawat = (soundType == 99 || prayerKey.lowercase() == "salawat")
        if (isSalawat) {
            playSalawat()
        } else {
            playAdhan(prayerKey, soundType, moazzenId)
        }

        return START_NOT_STICKY
    }

    private fun stopAll() {
        cancelSalawatFadeIn()
        salawatWasPausedForAdhan = false
        salawatPendingAfterAdhan = false
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
        // 1. If Adhan is CURRENTLY playing, DO NOT start Salawat now! Mark it pending to play right after Adhan completes.
        val aPlayer: MediaPlayer? = adhanPlayer
        if (aPlayer != null && aPlayer.isPlaying) {
            Log.d("AdhanService", "Adhan is currently playing. Postponing Salawat until Adhan completes.")
            salawatPendingAfterAdhan = true
            return
        }

        // 2. If Salawat is ALREADY playing, let it continue uninterrupted!
        val sPlayer: MediaPlayer? = salawatPlayer
        if (sPlayer != null && sPlayer.isPlaying) {
            Log.d("AdhanService", "Salawat is already playing, keeping it going.")
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
                    val activeAdhan: MediaPlayer? = adhanPlayer
                    if (activeAdhan == null || !activeAdhan.isPlaying) {
                        stopSelf()
                    }
                }
                setOnErrorListener { player, _, _ ->
                    cancelSalawatFadeIn()
                    player.release()
                    salawatPlayer = null
                    playSystemSalawatSound()
                    true
                }
                prepare()
                start()
                startSalawatFadeIn(this)
            }
        } catch (_: Exception) {
            Log.e("AdhanService", "Error playing salawat audio, falling back to system notification sound")
            playSystemSalawatSound()
        }
    }

    private fun playSystemSalawatSound() {
        try {
            val systemUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            if (systemUri == null) {
                stopSelf()
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
                    val activeAdhan: MediaPlayer? = adhanPlayer
                    if (activeAdhan == null || !activeAdhan.isPlaying) {
                        stopSelf()
                    }
                }
                setOnErrorListener { player, _, _ ->
                    cancelSalawatFadeIn()
                    player.release()
                    salawatPlayer = null
                    stopSelf()
                    true
                }
                prepare()
                start()
                startSalawatFadeIn(this)
            }
        } catch (e: Exception) {
            Log.e("AdhanService", "Error playing system salawat audio: ${e.message}")
            stopSelf()
        }
    }

    private fun playAdhan(prayerKey: String, soundType: Int, moazzenId: String) {
        // If Salawat is currently playing, PAUSE Salawat during Adhan!
        val sPlayer: MediaPlayer? = salawatPlayer
        if (sPlayer != null && sPlayer.isPlaying) {
            try {
                cancelSalawatFadeIn()
                sPlayer.pause()
                sPlayer.setVolume(1.0f, 1.0f)
                salawatWasPausedForAdhan = true
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
                    onAdhanAudioFinished()
                }
                setOnErrorListener { _, _, _ ->
                    adhanPlayer = null
                    playSystemAdhanSound()
                    true
                }
                prepare()
                start()
            }
        } catch (_: Exception) {
            Log.e("AdhanService", "Error playing adhan raw audio, falling back to system sound")
            playSystemAdhanSound()
        }
    }

    private fun playSystemAdhanSound() {
        try {
            val systemUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            if (systemUri == null) {
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
                    onAdhanAudioFinished()
                }
                setOnErrorListener { _, _, _ ->
                    adhanPlayer = null
                    onAdhanAudioFinished()
                    true
                }
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e("AdhanService", "Error playing system audio: ${e.message}")
            onAdhanAudioFinished()
        }
    }

    private fun onAdhanAudioFinished() {
        // 1. If Salawat was paused for Adhan, RESUME Salawat!
        if (salawatWasPausedForAdhan) {
            val salawat: MediaPlayer? = salawatPlayer
            if (salawat != null) {
                try {
                    salawat.start()
                    salawatWasPausedForAdhan = false
                    Log.d("AdhanService", "Salawat resumed after Adhan finished.")
                } catch (_: Exception) {
                    Log.e("AdhanService", "Failed to resume salawat after Adhan")
                    stopSelf()
                }
            } else {
                stopSelf()
            }
        } else if (salawatPendingAfterAdhan) {
            // 2. If Salawat triggered DURING Adhan, start Salawat NOW after Adhan completes!
            salawatPendingAfterAdhan = false
            Log.d("AdhanService", "Adhan completed, starting pending Salawat.")
            playSalawat()
        } else {
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

    private fun buildNotification(prayerName: String, prayerKey: String): android.app.Notification {
        val stopIntent = Intent(this, AdhanPlaybackService::class.java).apply {
            action = ACTION_STOP_ADHAN
        }
        
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        } else {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT
        }

        val stopPendingIntent = android.app.PendingIntent.getService(this, 0, stopIntent, flags)

        val isSalawat = prayerName.contains("النبي") || prayerName.contains("صل") || prayerKey.lowercase() == "salawat"
        val contentTitle = if (isSalawat) "صَلِّ عَلَى مُحَمَّدٍ ﷺ" else "حَانَ الْآنَ مَوْعِدُ صَلَاةِ $prayerName"
        val contentText = if (isSalawat) "اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ 🤍" else "أَقِمِ الصَّلَاةَ لِذِكْرِي"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(contentTitle)
            .setContentText(contentText)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(false) 
            .setDeleteIntent(stopPendingIntent)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "إيقاف الصوت", stopPendingIntent)
            .setSilent(true)
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(CHANNEL_ID, "تنبيهات الأذان والتسبيح", NotificationManager.IMPORTANCE_HIGH).apply {
            setSound(null, null)
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val EXTRA_PRAYER_KEY = "prayer_key"
        const val EXTRA_PRAYER_NAME = "prayer_name"
        const val EXTRA_SOUND_TYPE = "sound_type"
        const val EXTRA_MOAZZEN_ID = "moazzen_id"
        const val ACTION_STOP_ADHAN = "com.jimmy.religiousapp.STOP_ADHAN"
        private const val CHANNEL_ID = "native_adhan_playback_v3"
        private const val NOTIFICATION_ID = 9001
    }
}
