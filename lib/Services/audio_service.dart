import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(1.0);
      _isInitialized = true;
      print('✅ AudioService - تم تهيئة خدمة الصوت بنجاح');
    } catch (e) {
      print('❌ AudioService - خطأ في تهيئة خدمة الصوت: $e');
    }
  }

  Uint8List _generateBeepWav({
    int sampleRate = 22050,
    double frequency = 880.0,
    double durationSeconds = 0.5,
    double volume = 0.8,
  }) {
    final numSamples = (sampleRate * durationSeconds).round();
    final List<int> pcmData = [];

    for (int i = 0; i < numSamples; i++) {
      double envelope = 1.0;
      final fadeLen = (sampleRate * 0.04).round();
      if (i < fadeLen) envelope = i / fadeLen;
      if (i > numSamples - fadeLen) envelope = (numSamples - i) / fadeLen;

      final sample = (sin(2 * pi * frequency * i / sampleRate) *
              32767 *
              volume *
              envelope)
          .round()
          .clamp(-32768, 32767);
      pcmData.add(sample & 0xFF);
      pcmData.add((sample >> 8) & 0xFF);
    }

    final dataSize = pcmData.length;
    final byteRate = sampleRate * 2;

    final header = <int>[
      0x52, 0x49, 0x46, 0x46,
      (dataSize + 36) & 0xFF, ((dataSize + 36) >> 8) & 0xFF,
      ((dataSize + 36) >> 16) & 0xFF, ((dataSize + 36) >> 24) & 0xFF,
      0x57, 0x41, 0x56, 0x45,
      0x66, 0x6D, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00,
      0x01, 0x00,
      0x01, 0x00,
      sampleRate & 0xFF, (sampleRate >> 8) & 0xFF,
      (sampleRate >> 16) & 0xFF, (sampleRate >> 24) & 0xFF,
      byteRate & 0xFF, (byteRate >> 8) & 0xFF,
      (byteRate >> 16) & 0xFF, (byteRate >> 24) & 0xFF,
      0x02, 0x00,
      0x10, 0x00,
      0x64, 0x61, 0x74, 0x61,
      dataSize & 0xFF, (dataSize >> 8) & 0xFF,
      (dataSize >> 16) & 0xFF, (dataSize >> 24) & 0xFF,
    ];

    return Uint8List.fromList([...header, ...pcmData]);
  }

  Future<void> playNewOrderSound() async {
    try {
      if (!_isInitialized) await initialize();

      print('🔊 AudioService - تشغيل صوت إشعار الطلب الجديد');

      final beep1 = _generateBeepWav(frequency: 880.0, durationSeconds: 0.25);
      final beep2 = _generateBeepWav(frequency: 1100.0, durationSeconds: 0.25);

      await _audioPlayer.play(BytesSource(beep1));
      await Future.delayed(Duration(milliseconds: 300));

      await _audioPlayer.play(BytesSource(beep2));

      print('✅ AudioService - تم تشغيل الصوت بنجاح');
    } catch (e) {
      print('❌ AudioService - خطأ في تشغيل الصوت: $e');
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }
}
