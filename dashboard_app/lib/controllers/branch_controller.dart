import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BranchController extends GetxController {
  // قائمة الفروع المتاحة
  static const List<String> branches = [
    'الغزالية',
    'الزعفرانية',
    'الاعظمية',
    'العراق',
  ];
  
  // الفرع المختار حالياً
  final RxString selectedBranch = 'الغزالية'.obs;
  final RxBool isLoading = false.obs;
  
  // مفتاح SharedPreferences
  static const String _branchKey = 'selected_branch';
  
  @override
  void onInit() {
    super.onInit();
    _loadSelectedBranch();
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
    } catch (e) {
      print('❌ BranchController - خطأ في تحميل الفرع: $e');
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
  
  // الحصول على أيقونة الفرع
  String getBranchIcon(String branch) {
    switch (branch) {
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

