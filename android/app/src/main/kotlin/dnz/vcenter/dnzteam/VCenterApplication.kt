package dnz.vcenter.dnzteam

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentResolver
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build

/**
 * ينشئ قناة الإشعارات مع الصوت من raw قبل تشغيل Flutter،
 * حتى تكون جاهزة عند عرض إشعار FCM والتطبيق مغلق (قبل أي race مع Dart).
 * (Flutter 3.22+ يستخدم [Application] الافتراضي وليس FlutterApplication.)
 */
class VCenterApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannelWithSound()
    }

    private fun createNotificationChannelWithSound() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channelId = "high_importance_channel_v4"
        val soundUri = Uri.parse(
            "${ContentResolver.SCHEME_ANDROID_RESOURCE}://${packageName}/raw/vcenter_notify"
        )
        val channel = NotificationChannel(
            channelId,
            "إشعارات v center",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيهات مهمة مع صوت"
            setSound(
                soundUri,
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            enableVibration(true)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }
}
