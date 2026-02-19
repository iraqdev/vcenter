import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ecommerce/utils/apple_disclaimer.dart';

/// شاشة مخصصة لقطع غيار iPhone و iPad - لجعل المحتوى مناسباً لمستخدمي App Store (2.3.10)
class ApplePartsScreen extends StatelessWidget {
  const ApplePartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text('قطع غيار iPhone و iPad'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Get.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: Get.height * 0.02),
            // بطاقة ترحيب
            Container(
              padding: EdgeInsets.all(Get.width * 0.05),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.phone_iphone, size: 56, color: Colors.deepPurple.shade300),
                  SizedBox(height: Get.height * 0.02),
                  Text(
                    'قطع غيار أجهزة Apple',
                    style: TextStyle(
                      fontSize: Get.width * 0.055,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Get.height * 0.015),
                  Text(
                    'نوفر قطع غيار لأجهزة iPhone و iPad (غير أصلية من Apple). للاستفسار أو الطلب تواصل معنا.',
                    style: TextStyle(
                      fontSize: Get.width * 0.038,
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: Get.height * 0.025),
            // تنبيه Apple
            Container(
              padding: EdgeInsets.all(Get.width * 0.04),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppleDisclaimer.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Get.width * 0.04,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    AppleDisclaimer.body,
                    style: TextStyle(
                      fontSize: Get.width * 0.035,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Get.height * 0.03),
            // زر عرض الفئات
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.category_outlined),
              label: const Text('عرض جميع الفئات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
