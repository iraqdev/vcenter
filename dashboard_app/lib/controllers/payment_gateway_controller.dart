import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/dnz_payment_service.dart';

class PaymentGatewayController extends GetxController {
  final amountController = TextEditingController();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();

  final isLoading = false.obs;
  final paymentUrl = ''.obs;
  final paymentId = ''.obs;
  final paymentStatus = ''.obs;
  final isCheckingStatus = false.obs;

  Future<void> createLink() async {
    final amountText = amountController.text.trim().replaceAll(',', '');
    final amount = int.tryParse(amountText);
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (amount == null || amount <= 0) {
      Get.snackbar(
        'تنبيه',
        'أدخل مبلغاً صحيحاً بالدينار العراقي',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (name.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'أدخل الاسم',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (description.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'أدخل الوصف',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    paymentUrl.value = '';
    paymentId.value = '';
    paymentStatus.value = '';

    String? errorMsg;
    final result = await DnzPaymentService.createPaymentLink(
      amount: amount,
      productName: name,
      description: description,
      onError: (msg) => errorMsg = msg,
    );

    isLoading.value = false;

    if (result == null) {
      Get.snackbar(
        'خطأ',
        errorMsg ?? 'فشل إنشاء رابط الدفع',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    paymentUrl.value = result.paymentUrl;
    paymentId.value = result.paymentId;
    paymentStatus.value = 'pending';

    Get.snackbar(
      'تم',
      'تم إنشاء رابط الدفع بنجاح',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> copyLink() async {
    final url = paymentUrl.value.trim();
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    Get.snackbar(
      'تم',
      'تم نسخ الرابط',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> openLink() async {
    final url = paymentUrl.value.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      Get.snackbar(
        'خطأ',
        'تعذر فتح الرابط',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> refreshStatus() async {
    final id = paymentId.value.trim();
    if (id.isEmpty) return;

    isCheckingStatus.value = true;
    String? errorMsg;
    final status = await DnzPaymentService.getPaymentStatus(
      id,
      onError: (msg) => errorMsg = msg,
    );
    isCheckingStatus.value = false;

    if (status == null) {
      Get.snackbar(
        'خطأ',
        errorMsg ?? 'فشل جلب حالة الدفع',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    paymentStatus.value = status;
  }

  void clearResult() {
    paymentUrl.value = '';
    paymentId.value = '';
    paymentStatus.value = '';
  }

  @override
  void onClose() {
    amountController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
