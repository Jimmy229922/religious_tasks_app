package com.jimmy.religiousapp

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.util.Log

class AdhanPlaybackService : Service() {
    private var mediaPlayer: MediaPlayer? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP_ADHAN) {
            stopSelf()
            return START_NOT_STICKY
        }

        val prayerKey = intent?.getStringExtra(EXTRA_PRAYER_KEY) ?: "fajr"
        val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: "الصلاة"
        val soundType = intent?.getIntExtra(EXTRA_SOUND_TYPE, 0) ?: 0 // 0: none, 1: short, 2: full
        val moazzenId = intent?.getStringExtra(EXTRA_MOAZZEN_ID) ?: "default"

        startForeground(NOTIFICATION_ID, buildNotification(prayerName))
        
        if (soundType != 0) { // 0 is 'none' / silent
            playAdhan(prayerKey, soundType, moazzenId)
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        mediaPlayer = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun playAdhan(prayerKey: String, soundType: Int, moazzenId: String) {
        mediaPlayer?.release()

        val soundResId = if (soundType == 1) {
            R.raw.prayer_reminder
        } else {
            getAdhanResource(prayerKey, moazzenId)
        }

        if (soundResId == 0) {
            stopSelf()
            return
        }

        try {
            val descriptor = resources.openRawResourceFd(soundResId) ?: return
            mediaPlayer = MediaPlayer().apply {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                }
                setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                descriptor.close()
                setOnCompletionListener {
                    stopSelf()
                }
                setOnErrorListener { _, _, _ ->
                    stopSelf()
                    true
                }
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e("AdhanService", "Error playing adhan")
            stopSelf()
        }
    }

    private fun getAdhanResource(prayerKey: String, moazzenId: String): Int {
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

    private fun buildNotification(prayerName: String): android.app.Notification {
        val stopIntent = Intent(this, AdhanPlaybackService::class.java).apply {
            action = ACTION_STOP_ADHAN
        }
        
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
        } else {
            android.app.PendingIntent.FLAG_UPDATE_CURRENT
        }

        val stopPendingIntent = android.app.PendingIntent.getService(this, 0, stopIntent, flags)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("حان الآن موعد صلاة $prayerName")
            .setContentText("أقم صلاتك تنعم بحياتك")
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
        val channel = NotificationChannel(CHANNEL_ID, "تنبيهات الأذان", NotificationManager.IMPORTANCE_HIGH).apply {
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
