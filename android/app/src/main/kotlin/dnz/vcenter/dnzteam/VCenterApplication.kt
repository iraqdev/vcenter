package dnz.vcenter.dnzteam

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.util.Log

/**
 * ينشئ قناة vcenter_push_v3 مرة واحدة مع Importance.HIGH + صوت النظام DEFAULT.
 * لا نحذف v3 بعد إنشائها حتى لا تُعاد بدون صوت.
 */
class VCenterApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannelWithSound()
    }

    private fun createNotificationChannelWithSound() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val channelId = "vcenter_push_v3"

        // احذف القنوات القديمة فقط — لا تحذف v3 إذا كانت موجودة بصوت صحيح
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

        val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val channel = NotificationChannel(
            channelId,
            "إشعارات v center",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيهات مع صوت النظام"
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
        Log.i(TAG, "Created channel $channelId with DEFAULT notification sound")
    }

    companion object {
        private const val TAG = "VCenterNotify"
    }
}
