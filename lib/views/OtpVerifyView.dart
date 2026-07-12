import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../Services/whatsapp_otp_service.dart';

/// شاشة إدخال رمز واتساب — تُستخدم بعد طلب OTP للتسجيل أو الاستعادة.
class OtpVerifyView extends StatefulWidget {
  const OtpVerifyView({
    super.key,
    required this.phone,
    required this.purpose,
    required this.onVerified,
    this.title = 'تأكيد رقم الهاتف',
    this.subtitle,
    this.serverVerify = true,
  });

  final String phone;
  final String purpose;
  final Future<void> Function(String code) onVerified;
  final String title;
  final String? subtitle;
  /// إن كان false يمرّر الرمز فقط (مثلاً لنسيت كلمة السر حيث التحقق عند الحفظ).
  final bool serverVerify;

  @override
  State<OtpVerifyView> createState() => _OtpVerifyViewState();
}

class _OtpVerifyViewState extends State<OtpVerifyView> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown(60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _resendSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 1) {
        t.cancel();
        if (mounted) setState(() => _resendSeconds = 0);
      } else if (mounted) {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'أدخل رمز التحقق المكوّن من 6 أرقام.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.serverVerify) {
        final result = await WhatsAppOtpService.verifyOtp(
          phone: widget.phone,
          purpose: widget.purpose,
          code: code,
        );
        if (result['ok'] != true) {
          setState(() {
            _error = result['message']?.toString() ?? 'رمز التحقق غير صحيح.';
            _loading = false;
          });
          return;
        }
      }
      await widget.onVerified(code);
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      setState(() {
        _error = 'حدث خطأ. حاول مرة أخرى.';
        _loading = false;
      });
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    final result = await WhatsAppOtpService.requestOtp(
      phone: widget.phone,
      purpose: widget.purpose,
    );
    setState(() => _resending = false);
    if (result['ok'] == true) {
      final wait = (result['resendInSec'] as num?)?.toInt() ?? 60;
      _startResendCountdown(wait);
      Get.snackbar(
        'تم',
        'أُعيد إرسال الرمز عبر واتساب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade600,
        colorText: Colors.white,
      );
    } else {
      final wait = (result['waitSec'] as num?)?.toInt();
      if (wait != null && wait > 0) _startResendCountdown(wait);
      setState(() {
        _error = result['message']?.toString() ?? 'فشل إعادة الإرسال.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Get.height * 0.028,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle ??
                      'أدخل الرمز المرسل عبر واتساب إلى\n${widget.phone}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Get.height * 0.015,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          letterSpacing: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '------',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _loading
                              ? LoadingAnimationWidget.staggeredDotsWave(
                                  color: Colors.white,
                                  size: 28,
                                )
                              : const Text(
                                  'تأكيد الرمز',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: (_resendSeconds > 0 || _resending)
                            ? null
                            : _resend,
                        child: Text(
                          _resending
                              ? 'جاري الإرسال...'
                              : _resendSeconds > 0
                                  ? 'إعادة الإرسال بعد $_resendSeconds ث'
                                  : 'إعادة إرسال الرمز',
                          style: TextStyle(
                            color: _resendSeconds > 0
                                ? Colors.grey
                                : Colors.deepPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
