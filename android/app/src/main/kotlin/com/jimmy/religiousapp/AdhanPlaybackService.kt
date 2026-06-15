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
        val prayerKey = intent?.getStringExtra(EXTRA_PRAYER_KEY) ?: "fajr"
        val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: "الصلاة"

        startForeground(NOTIFICATION_ID, buildNotification(prayerName))
        playAdhan(prayerKey)

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        mediaPlayer?.release()
        mediaPlayer = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun playAdhan(prayerKey: String) {
        mediaPlayer?.release()

        val soundResId = when (prayerKey) {
            "fajr" -> R.raw.adhan_fajr
            "dhuhr" -> R.raw.adhan_dhuhr
            "asr" -> R.raw.adhan_asr
            "maghrib" -> R.raw.adhan_maghrib
            "isha" -> R.raw.adhan_isha
            else -> R.raw.prayer_reminder
        }

        val descriptor = resources.openRawResourceFd(soundResId) ?: return

        mediaPlayer = MediaPlayer().apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
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
    }

    private fun buildNotification(prayerName: String) =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("وقت الأذان")
            .setContentText("حان الآن وقت صلاة $prayerName")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setSilent(true)
            .build()

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "تشغيل الأذان",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            setSound(null, null)
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    companion object {
        const val EXTRA_PRAYER_KEY = "prayer_key"
        const val EXTRA_PRAYER_NAME = "prayer_name"
        private const val CHANNEL_ID = "native_adhan_playback"
        private const val NOTIFICATION_ID = 9001
    }
}
