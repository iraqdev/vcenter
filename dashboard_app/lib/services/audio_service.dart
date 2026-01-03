import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  // تهيئة خدمة الصوت
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // إعداد AudioPlayer
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
      
      _isInitialized = true;
      print('✅ AudioService - تم تهيئة خدمة الصوت بنجاح');
    } catch (e) {
      print('❌ AudioService - خطأ في تهيئة خدمة الصوت: $e');
    }
  }

  // تشغيل صوت إشعار الطلب الجديد
  Future<void> playNewOrderSound() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      print('🔊 AudioService - تشغيل صوت إشعار الطلب الجديد');
      
      // استخدام صوت النظام الافتراضي للإشعارات
      await _audioPlayer.play(AssetSource('sounds/new_order_notification.mp3'));
      
      print('✅ AudioService - تم تشغيل الصوت بنجاح');
    } catch (e) {
      print('❌ AudioService - خطأ في تشغيل الصوت: $e');
      
      // في حالة عدم وجود ملف صوتي، استخدم صوت النظام
      try {
        await SystemSound.play(SystemSoundType.alert);
        print('✅ AudioService - تم تشغيل صوت النظام كبديل');
      } catch (systemSoundError) {
        print('❌ AudioService - فشل في تشغيل صوت النظام: $systemSoundError');
      }
    }
  }

  // تشغيل صوت إشعار عام
  Future<void> playNotificationSound() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      print('🔊 AudioService - تشغيل صوت إشعار عام');
      
      // استخدام صوت النظام للإشعارات العامة
      await SystemSound.play(SystemSoundType.alert);
      
      print('✅ AudioService - تم تشغيل صوت الإشعار العام');
    } catch (e) {
      print('❌ AudioService - خطأ في تشغيل صوت الإشعار العام: $e');
    }
  }

  // إيقاف الصوت
  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      print('🔇 AudioService - تم إيقاف الصوت');
    } catch (e) {
      print('❌ AudioService - خطأ في إيقاف الصوت: $e');
    }
  }

  // تغيير مستوى الصوت
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      print('🔊 AudioService - تم تغيير مستوى الصوت إلى: $volume');
    } catch (e) {
      print('❌ AudioService - خطأ في تغيير مستوى الصوت: $e');
    }
  }

  // تنظيف الموارد
  Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      print('🧹 AudioService - تم تنظيف الموارد');
    } catch (e) {
      print('❌ AudioService - خطأ في تنظيف الموارد: $e');
    }
  }
}
