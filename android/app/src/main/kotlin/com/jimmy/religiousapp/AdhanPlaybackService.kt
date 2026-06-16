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

        startForeground(NOTIFICATION_ID, buildNotification(prayerName))
        
        if (soundType != 0) { // 0 is 'none' / silent
            playAdhan(prayerKey, soundType)
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        mediaPlayer = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun playAdhan(prayerKey: String, soundType: Int) {
        mediaPlayer?.release()

        val soundResId = if (soundType == 1) { // Short sound
            if (prayerKey == "sunrise") R.raw.prayer_reminder else R.raw.prayer_reminder 
            // يمكنك تخصيص صوت قصير هنا، حالياً نستخدم prayer_reminder
            R.raw.prayer_reminder
        } else { // Full Adhan
            when (prayerKey) {
                "fajr" -> R.raw.adhan_fajr
                "dhuhr" -> R.raw.adhan_dhuhr
                "asr" -> R.raw.adhan_asr
                "maghrib" -> R.raw.adhan_maghrib
                "isha" -> R.raw.adhan_isha
                else -> R.raw.prayer_reminder
            }
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
            stopSelf()
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
            .setSilent(true) // We handle sound via MediaPlayer for better control
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
        const val ACTION_STOP_ADHAN = "com.jimmy.religiousapp.STOP_ADHAN"
        private const val CHANNEL_ID = "native_adhan_playback_v2"
        private const val NOTIFICATION_ID = 9001
    }
}
