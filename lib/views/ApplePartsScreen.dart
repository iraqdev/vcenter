import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// شاشة مخصصة لقطع غيار iPhone و iPad
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
                    'نوفر قطع غيار لأجهزة iPhone و iPad. للاستفسار أو الطلب تواصل معنا.',
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
            SizedBox(height: Get.height * 0.02),
            Container(
              padding: EdgeInsets.all(Get.width * 0.04),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFD28A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFB26A00)),
                  SizedBox(width: Get.width * 0.03),
                  Expanded(
                    child: Text(
                      'تنبيه مهم: لا نستخدم قطع Apple الأصلية من الشركة الأم في خدمات الصيانة. استخدام خدماتنا قد يؤدي إلى إلغاء ضمان Apple للجهاز.',
                      style: TextStyle(
                        fontSize: Get.width * 0.036,
                        height: 1.45,
                        color: const Color(0xFF5A3A00),
                        fontWeight: FontWeight.w600,
                      ),
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
