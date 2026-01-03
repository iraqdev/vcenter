import 'package:get/get.dart';
import '../models/subcategory_model.dart';
import '../services/subcategory_service.dart';

class SubCategoryController extends GetxController {
  final RxList<SubCategoryModel> subCategories = <SubCategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxInt selectedCategoryId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔍 SubCategoryController - تهيئة المتحكم');
    loadSubCategories();
  }

  // جلب جميع الفئات الفرعية
  Future<void> loadSubCategories() async {
    try {
      isLoading.value = true;
      print('🔍 SubCategoryController - جلب الفئات الفرعية...');
      final fetchedSubCategories = await SubCategoryService.getAllSubCategories();
      subCategories.assignAll(fetchedSubCategories);
      print('✅ SubCategoryController - تم جلب ${fetchedSubCategories.length} فئة فرعية');
      
      // طباعة الفئات الفرعية للتشخيص
      for (var subCat in fetchedSubCategories.take(5)) {
        print('📂 فئة فرعية: ${subCat.title}, category: ${subCat.category}, originalId: ${subCat.originalId}');
      }
    } catch (e) {
      print('❌ خطأ في جلب الفئات الفرعية: $e');
      Get.snackbar('خطأ', 'فشل في جلب الفئات الفرعية');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب الفئات الفرعية حسب الفئة الرئيسية
  Future<void> loadSubCategoriesByCategory(int categoryId) async {
    try {
      isLoading.value = true;
      selectedCategoryId.value = categoryId;
      final fetchedSubCategories = await SubCategoryService.getSubCategoriesByCategory(categoryId);
      subCategories.assignAll(fetchedSubCategories);
    } catch (e) {
      print('خطأ في جلب الفئات الفرعية حسب الفئة: $e');
      Get.snackbar('خطأ', 'فشل في جلب الفئات الفرعية');
    } finally {
      isLoading.value = false;
    }
  }

  // البحث في الفئات الفرعية
  List<SubCategoryModel> get filteredSubCategories {
    if (searchQuery.value.isEmpty) {
      return subCategories;
    }
    return subCategories.where((subCategory) {
      return subCategory.title.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  // الحصول على اسم الفئة الفرعية بالمعرف الأصلي
  String getSubCategoryName(int originalId) {
    try {
      final subCategory = subCategories.firstWhere((c) => c.originalId == originalId);
      return subCategory.title;
    } catch (e) {
      return 'فئة فرعية $originalId';
    }
  }

  // الحصول على الفئة الفرعية بالمعرف الأصلي
  SubCategoryModel? getSubCategoryByOriginalId(int originalId) {
    try {
      return subCategories.firstWhere((c) => c.originalId == originalId);
    } catch (e) {
      return null;
    }
  }

  // الحصول على الفئات الفرعية حسب الفئة الرئيسية
  List<SubCategoryModel> getSubCategoriesByCategory(int categoryId) {
    return subCategories.where((c) => c.category == categoryId).toList();
  }

  // تحديث فئة فرعية
  Future<bool> updateSubCategory(String id, Map<String, dynamic> data) async {
    try {
      final success = await SubCategoryService.updateSubCategory(id, data);
      if (success) {
        await loadSubCategories(); // إعادة تحميل الفئات الفرعية
        Get.snackbar('نجح', 'تم تحديث الفئة الفرعية بنجاح');
      }
      return success;
    } catch (e) {
      print('خطأ في تحديث الفئة الفرعية: $e');
      Get.snackbar('خطأ', 'فشل في تحديث الفئة الفرعية');
      return false;
    }
  }

  // حذف فئة فرعية
  Future<bool> deleteSubCategory(String id) async {
    try {
      final success = await SubCategoryService.deleteSubCategory(id);
      if (success) {
        await loadSubCategories(); // إعادة تحميل الفئات الفرعية
        Get.snackbar('نجح', 'تم حذف الفئة الفرعية بنجاح');
      }
      return success;
    } catch (e) {
      print('خطأ في حذف الفئة الفرعية: $e');
      Get.snackbar('خطأ', 'فشل في حذف الفئة الفرعية');
      return false;
    }
  }

  // إضافة فئة فرعية جديدة
  Future<String?> addSubCategory(SubCategoryModel subCategory) async {
    try {
      final id = await SubCategoryService.addSubCategory(subCategory);
      if (id != null) {
        await loadSubCategories(); // إعادة تحميل الفئات الفرعية
        Get.snackbar('نجح', 'تم إضافة الفئة الفرعية بنجاح');
      }
      return id;
    } catch (e) {
      print('خطأ في إضافة الفئة الفرعية: $e');
      Get.snackbar('خطأ', 'فشل في إضافة الفئة الفرعية');
      return null;
    }
  }

  // تحديث استعلام البحث
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  // تحديث الفئة المحددة
  void setSelectedCategory(int categoryId) {
    selectedCategoryId.value = categoryId;
    loadSubCategoriesByCategory(categoryId);
  }

  // إحصائيات الفئات الفرعية
  Map<String, int> get subCategoryStats {
    return {
      'total': subCategories.length,
      'active': subCategories.where((c) => c.active).length,
      'inactive': subCategories.where((c) => !c.active).length,
    };
  }

  // تحديث البيانات
  Future<void> refresh() async {
    await loadSubCategories();
  }
}
