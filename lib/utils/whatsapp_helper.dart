import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/main.dart';

class WhatsAppHelper {
  // قائمة الفروع مع أرقام الهواتف
  static final Map<String, String> branchPhones = {
    'الاعظمية': '07761620356',
    'الغزالية': '07775124916', 
    'الزعفرانية': '07752855594',
    'العراق': '07874223116',
  };

  // فتح واتساب للفرع المناسب حسب closestBranch
  static Future<void> openWhatsappForUserBranch() async {
    try {
      // الحصول على رقم الهاتف من SharedPreferences
      final phone = sharedPreferences?.getString('phone');
      if (phone == null || phone.isEmpty) {
        Get.snackbar('خطأ', 'لم يتم العثور على بيانات المستخدم');
        return;
      }

      // البحث عن المستخدم في Firebase للحصول على closestBranch
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        Get.snackbar('خطأ', 'لم يتم العثور على بيانات المستخدم في قاعدة البيانات');
        return;
      }

      final userData = usersSnapshot.docs.first.data();
      final closestBranch = userData['closestBranch'] as String?;

      if (closestBranch == null || closestBranch.isEmpty) {
        // إذا لم يكن هناك closestBranch، عرض قائمة الفروع
        _showBranchSelection();
        return;
      }

      // البحث عن رقم الهاتف للفرع المناسب
      final branchPhone = branchPhones[closestBranch];
      if (branchPhone == null) {
        Get.snackbar('خطأ', 'لم يتم العثور على رقم هاتف للفرع: $closestBranch');
        return;
      }

      // فتح واتساب مباشرة للفرع المناسب
      await _openWhatsappBranch(branchPhone, closestBranch);
      
    } catch (e) {
      print('خطأ في فتح واتساب: $e');
      Get.snackbar('خطأ', 'حدث خطأ في فتح واتساب: ${e.toString()}');
    }
  }

  // إظهار قائمة اختيار الفرع (في حالة عدم وجود closestBranch)
  static void _showBranchSelection() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مؤشر السحب
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'اختر الفرع',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 20),
            ...branchPhones.entries.map((entry) => Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    Get.back(); // إغلاق القائمة
                    await _openWhatsappBranch(entry.value, entry.key);
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.whatsapp,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.green,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )).toList(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // فتح واتساب للفرع المحدد
  static Future<void> _openWhatsappBranch(String phoneNumber, String branchName) async {
    final link = WhatsAppUnilink(
      phoneNumber: phoneNumber,
      text: "مرحبا، أريد الاستفسار عن فرع $branchName",
    );

    final String url = link.asUri().toString();
    await launchUrl(Uri.parse(url));
  }
}
