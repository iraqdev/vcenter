import 'package:get/get.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryController extends GetxController {
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxInt selectedCategoryId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  // جلب جميع الفئات
  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      final fetchedCategories = await CategoryService.getAllCategories();
      categories.assignAll(fetchedCategories);
    } catch (e) {
      print('خطأ في جلب الفئات: $e');
      Get.snackbar('خطأ', 'فشل في جلب الفئات');
    } finally {
      isLoading.value = false;
    }
  }

  // البحث في الفئات
  List<CategoryModel> get filteredCategories {
    if (searchQuery.value.isEmpty) {
      return categories;
    }
    return categories.where((category) {
      return category.title.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  // الحصول على اسم الفئة بالمعرف الأصلي
  String getCategoryName(int originalId) {
    try {
      final category = categories.firstWhere((c) => c.originalId == originalId);
      return category.title;
    } catch (e) {
      return 'فئة $originalId';
    }
  }

  // الحصول على الفئة بالمعرف الأصلي
  CategoryModel? getCategoryByOriginalId(int originalId) {
    try {
      return categories.firstWhere((c) => c.originalId == originalId);
    } catch (e) {
      return null;
    }
  }

  // تحديث فئة
  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final success = await CategoryService.updateCategory(id, data);
      if (success) {
        await loadCategories(); // إعادة تحميل الفئات
        Get.snackbar('نجح', 'تم تحديث الفئة بنجاح');
      }
      return success;
    } catch (e) {
      print('خطأ في تحديث الفئة: $e');
      Get.snackbar('خطأ', 'فشل في تحديث الفئة');
      return false;
    }
  }

  // حذف فئة
  Future<bool> deleteCategory(String id) async {
    try {
      final success = await CategoryService.deleteCategory(id);
      if (success) {
        await loadCategories(); // إعادة تحميل الفئات
        Get.snackbar('نجح', 'تم حذف الفئة بنجاح');
      }
      return success;
    } catch (e) {
      print('خطأ في حذف الفئة: $e');
      Get.snackbar('خطأ', 'فشل في حذف الفئة');
      return false;
    }
  }

  // إضافة فئة جديدة
  Future<String?> addCategory(CategoryModel category) async {
    try {
      final id = await CategoryService.addCategory(category);
      if (id != null) {
        await loadCategories(); // إعادة تحميل الفئات
        Get.snackbar('نجح', 'تم إضافة الفئة بنجاح');
      }
      return id;
    } catch (e) {
      print('خطأ في إضافة الفئة: $e');
      Get.snackbar('خطأ', 'فشل في إضافة الفئة');
      return null;
    }
  }

  // تحديث استعلام البحث
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  // تحديث الفئة المحددة
  void setSelectedCategory(int originalId) {
    selectedCategoryId.value = originalId;
  }

  // إحصائيات الفئات
  Map<String, int> get categoryStats {
    return {
      'total': categories.length,
      'active': categories.where((c) => c.active).length,
      'inactive': categories.where((c) => !c.active).length,
    };
  }
}
