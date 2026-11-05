package com.example.dashboard_app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.util.Log

/**
 * قناة vcenter_push_v3 تطابق ما ترسله Cloud Functions / DNZ،
 * مع صوت الداشبورد الحالي (vcenter_notify).
 */
class DashboardApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannelWithSound()
    }

    private fun createNotificationChannelWithSound() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val channelId = "vcenter_push_v3"

        listOf(
            "high_importance_channel_v4",
            "high_importance_channel_v5",
            "vcenter_push_v1",
            "vcenter_push_v2",
            "dnz_channel",
            "dnz_channel_v3",
        ).forEach { oldId ->
            try {
                manager.deleteNotificationChannel(oldId)
            } catch (_: Exception) {
            }
        }

        val existing = manager.getNotificationChannel(channelId)
        if (existing != null) {
            Log.i(TAG, "Channel $channelId already exists (importance=${existing.importance})")
            return
        }

        val soundUri = Uri.parse("android.resource://$packageName/raw/vcenter_notify")
        val channel = NotificationChannel(
            channelId,
            "إشعارات الداشبورد",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيهات DNZ مع صوت"
            setSound(
                soundUri,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            enableVibration(true)
            setShowBadge(true)
        }
        manager.createNotificationChannel(channel)
        Log.i(TAG, "Created channel $channelId with vcenter_notify")
    }

    companion object {
        private const val TAG = "DashboardNotify"
    }
}
