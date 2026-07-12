import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../Services/whatsapp_otp_service.dart';
import 'OtpVerifyView.dart';

class ForgotPasswordController extends GetxController {
  final phone_ = TextEditingController();
  final newPassword_ = TextEditingController();
  final confirmPassword_ = TextEditingController();

  bool loading = false;
  bool error = false;
  String errormsg = '';

  void clearError() {
    error = false;
    errormsg = '';
    update();
  }

  void _setError(String msg) {
    errormsg = msg;
    error = true;
    loading = false;
    update();
  }

  Future<void> submitPhone() async {
    clearError();
    final phone = phone_.text.trim();
    if (phone.isEmpty) {
      _setError('يرجى إدخال رقم الهاتف.');
      return;
    }
    if (phone.length != 11 || !phone.startsWith('07')) {
      _setError('رقم الهاتف غير صحيح. يجب أن يكون 11 رقم ويبدأ بـ 07.');
      return;
    }

    loading = true;
    update();

    final result = await WhatsAppOtpService.requestOtp(
      phone: phone,
      purpose: 'reset',
    );

    loading = false;
    update();

    if (result['ok'] != true) {
      _setError(result['message']?.toString() ?? 'فشل إرسال رمز التحقق.');
      return;
    }

    Get.to(
      () => OtpVerifyView(
        phone: phone,
        purpose: 'reset',
        title: 'تأكيد الهوية',
        serverVerify: false,
        onVerified: (code) async {
          Get.off(
            () => _NewPasswordPage(
              phone: phone,
              code: code,
            ),
          );
        },
      ),
    );
  }

  @override
  void onClose() {
    phone_.dispose();
    newPassword_.dispose();
    confirmPassword_.dispose();
    super.onClose();
  }
}

class ForgotPasswordView extends StatelessWidget {
  ForgotPasswordView({super.key});
  final ForgotPasswordController controller =
      Get.put(ForgotPasswordController());

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
              children: [
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                SizedBox(height: Get.height * 0.03),
                Text(
                  'نسيت كلمة السر',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Get.height * 0.03,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أدخل رقم هاتفك لإرسال رمز التحقق عبر واتساب',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Get.height * 0.015,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: Get.height * 0.035),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
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
                  child: TextField(
                    controller: controller.phone_,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'رقم الهاتف',
                      hintStyle:
                          TextStyle(color: Colors.grey[500], fontSize: 14),
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GetBuilder<ForgotPasswordController>(
                  builder: (c) {
                    if (c.loading) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        height: 50,
                        child: Center(
                          child: LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      );
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      height: 50,
                      child: ElevatedButton(
                        onPressed: c.submitPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'إرسال رمز التحقق',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                GetBuilder<ForgotPasswordController>(
                  builder: (c) {
                    if (!c.error) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Text(
                        c.errormsg,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red[100],
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewPasswordPage extends StatefulWidget {
  const _NewPasswordPage({
    required this.phone,
    required this.code,
  });

  final String phone;
  final String code;

  @override
  State<_NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<_NewPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pass = _password.text.trim();
    final confirm = _confirm.text.trim();
    if (pass.length < 6) {
      setState(() => _error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await WhatsAppOtpService.resetPassword(
      phone: widget.phone,
      code: widget.code,
      newPassword: pass,
    );

    if (result['ok'] != true) {
      setState(() {
        _loading = false;
        _error = result['message']?.toString() ?? 'فشل تغيير كلمة المرور.';
      });
      return;
    }

    Get.offAllNamed('/');
    Get.snackbar(
      'تم',
      'تم تغيير كلمة المرور. سجّل الدخول الآن.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
    );
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
                const SizedBox(height: 40),
                Text(
                  'كلمة مرور جديدة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Get.height * 0.028,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'كلمة المرور الجديدة',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'تأكيد كلمة المرور',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red[600], fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: _loading
                              ? LoadingAnimationWidget.staggeredDotsWave(
                                  color: Colors.white,
                                  size: 26,
                                )
                              : const Text('حفظ كلمة المرور'),
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
