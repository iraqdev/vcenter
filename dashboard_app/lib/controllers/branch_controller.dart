import 'package:get/get.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BranchController extends GetxController {
  // قائمة الفروع المتاحة (المسؤول يظهر كل شيء)
  static const List<String> branches = [
    'المسؤول',
    'الغزالية',
    'الزعفرانية',
    'الاعظمية',
    'العراق',
  ];
  
  // الفرع المختار حالياً
  final RxString selectedBranch = 'الغزالية'.obs;
  final RxBool isLoading = false.obs;
  StreamSubscription<String>? _tokenRefreshSubscription;
  
  // مفتاح SharedPreferences
  static const String _branchKey = 'selected_branch';
  
  @override
  void onInit() {
    super.onInit();
    _loadSelectedBranch();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      _updateDashboardDevice(selectedBranch.value);
    });
  }

  @override
  void onClose() {
    _tokenRefreshSubscription?.cancel();
    super.onClose();
  }
  
  // تحميل الفرع المختار من SharedPreferences
  Future<void> _loadSelectedBranch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBranch = prefs.getString(_branchKey);
      
      if (savedBranch != null && branches.contains(savedBranch)) {
        selectedBranch.value = savedBranch;
        print('✅ BranchController - تم تحميل الفرع المحفوظ: $savedBranch');
      } else {
        // حفظ الفرع الافتراضي
        await _saveSelectedBranch(selectedBranch.value);
        print('✅ BranchController - تم تعيين الفرع الافتراضي: ${selectedBranch.value}');
      }
      await _updateDashboardDevice(selectedBranch.value);
    } catch (e) {
      print('❌ BranchController - خطأ في تحميل الفرع: $e');
    }
  }

  /// تحديث سجل جهاز الداشبورد مع الفرع الحالي وتوكن FCM
  Future<void> _updateDashboardDevice(String branch) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        print('❌ BranchController - لا يوجد FCM token');
        return;
      }
      await FirebaseFirestore.instance.collection('dashboard_devices').doc(token).set({
        'token': token,
        'branch': branch,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ BranchController - تم تحديث جهاز الداش للفرع: $branch');
    } catch (e) {
      print('❌ BranchController - خطأ في تحديث جهاز الداش: $e');
    }
  }
  
  // حفظ الفرع المختار إلى SharedPreferences
  Future<void> _saveSelectedBranch(String branch) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_branchKey, branch);
      print('✅ BranchController - تم حفظ الفرع: $branch');
    } catch (e) {
      print('❌ BranchController - خطأ في حفظ الفرع: $e');
    }
  }
  
  // تغيير الفرع المختار
  Future<void> changeBranch(String branch) async {
    if (!branches.contains(branch)) {
      print('❌ BranchController - فرع غير صالح: $branch');
      return;
    }
    
    isLoading.value = true;
    
    try {
      selectedBranch.value = branch;
      await _saveSelectedBranch(branch);
      await _updateDashboardDevice(branch);
      
      print('✅ BranchController - تم تغيير الفرع إلى: $branch');
      
      // إعادة تحميل الطلبات للفرع الجديد
      // سيتم استدعاء هذا من OrderController
      Get.snackbar(
        'تم التغيير',
        'تم التبديل إلى فرع $branch',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 2),
      );
      
    } catch (e) {
      print('❌ BranchController - خطأ في تغيير الفرع: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  // الحصول على اسم الفرع بالإنجليزية (للاستخدام في المفاتيح)
  String getBranchKey() {
    switch (selectedBranch.value) {
      case 'المسؤول':
        return 'admin';
      case 'الغزالية':
        return 'ghazaliya';
      case 'الزعفرانية':
        return 'zafaraniya';
      case 'الاعظمية':
        return 'adhamiya';
      case 'العراق':
        return 'iraq';
      default:
        return 'iraq';
    }
  }

  // هل الفرع الحالي هو المسؤول (يعرض كل البيانات بدون عزل)
  bool get isAdminBranch => selectedBranch.value == 'المسؤول';
  
  // الحصول على أيقونة الفرع
  String getBranchIcon(String branch) {
    switch (branch) {
      case 'المسؤول':
        return '👑';
      case 'الغزالية':
        return '🏢';
      case 'الزعفرانية':
        return '🏪';
      case 'الاعظمية':
        return '🏬';
      case 'العراق':
        return '🇮🇶';
      default:
        return '📍';
    }
  }
}

