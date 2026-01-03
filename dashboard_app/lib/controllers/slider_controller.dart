import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/slider_model.dart';
import '../services/slider_service.dart';

class SliderController extends GetxController {
  final RxList<SliderModel> sliders = <SliderModel>[].obs;
  final RxList<SliderModel> filteredSliders = <SliderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // البحث والفلترة
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs; // 'all', 'active', 'inactive'
  final RxString sortBy = 'createdAt'.obs;
  final RxBool sortDescending = true.obs;

  // الإحصائيات
  final RxMap<String, int> stats = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSliders();
    fetchStats();
  }

  // جلب جميع العروض
  Future<void> fetchSliders() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔄 بدء جلب العروض...');
      final fetchedSliders = await SliderService.getAllSliders();
      print('📊 تم جلب ${fetchedSliders.length} عرض');
      
      sliders.value = fetchedSliders;
      _applyFilters();

    } catch (e) {
      errorMessage.value = 'خطأ في جلب العروض: $e';
      print('❌ خطأ في جلب العروض: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب الإحصائيات
  Future<void> fetchStats() async {
    try {
      final allSliders = await SliderService.getAllSliders();
      final activeSliders = allSliders.where((s) => s.active).length;
      final inactiveSliders = allSliders.where((s) => !s.active).length;

      stats.value = {
        'total': allSliders.length,
        'active': activeSliders,
        'inactive': inactiveSliders,
      };
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
    }
  }

  // إضافة عرض جديد
  Future<bool> addSlider(SliderModel slider) async {
    try {
      isLoading.value = true;
      
      final success = await SliderService.addSlider(slider);
      
      if (success) {
        await fetchSliders();
        await fetchStats();
        Get.snackbar(
          'نجح',
          'تم إضافة العرض بنجاح',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
        return true;
      } else {
        Get.snackbar(
          'خطأ',
          'فشل في إضافة العرض',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في إضافة العرض: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // تحديث عرض
  Future<bool> updateSlider(String id, SliderModel slider) async {
    try {
      isLoading.value = true;
      
      final success = await SliderService.updateSlider(id, slider);
      
      if (success) {
        await fetchSliders();
        await fetchStats();
        Get.snackbar(
          'نجح',
          'تم تحديث العرض بنجاح',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
        return true;
      } else {
        Get.snackbar(
          'خطأ',
          'فشل في تحديث العرض',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث العرض: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // حذف عرض
  Future<bool> deleteSlider(String id) async {
    try {
      isLoading.value = true;
      
      final success = await SliderService.deleteSlider(id);
      
      if (success) {
        await fetchSliders();
        await fetchStats();
        Get.snackbar(
          'نجح',
          'تم حذف العرض بنجاح',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
        return true;
      } else {
        Get.snackbar(
          'خطأ',
          'فشل في حذف العرض',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حذف العرض: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // تبديل حالة العرض
  Future<bool> toggleSliderStatus(String id, bool active) async {
    try {
      final success = await SliderService.toggleSliderStatus(id, active);
      
      if (success) {
        await fetchSliders();
        await fetchStats();
        Get.snackbar(
          'نجح',
          'تم تحديث حالة العرض بنجاح',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
        return true;
      } else {
        Get.snackbar(
          'خطأ',
          'فشل في تحديث حالة العرض',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة العرض: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // تطبيق الفلاتر
  void _applyFilters() {
    List<SliderModel> filtered = List.from(sliders);

    // فلترة حسب النص
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((slider) =>
          slider.title.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
    }

    // فلترة حسب الحالة
    if (selectedStatus.value != 'all') {
      final isActive = selectedStatus.value == 'active';
      filtered = filtered.where((slider) => slider.active == isActive).toList();
    }

    // ترتيب
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy.value) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'createdAt':
          comparison = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
          break;
        default:
          comparison = 0;
      }
      
      return sortDescending.value ? -comparison : comparison;
    });

    filteredSliders.value = filtered;
  }

  // تحديث البحث
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  // تحديث فلتر الحالة
  void updateStatusFilter(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  // تحديث الترتيب
  void updateSorting(String field, bool descending) {
    sortBy.value = field;
    sortDescending.value = descending;
    _applyFilters();
  }

  // مسح الفلاتر
  void clearFilters() {
    searchQuery.value = '';
    selectedStatus.value = 'all';
    sortBy.value = 'createdAt';
    sortDescending.value = true;
    _applyFilters();
  }

  // تحديث البيانات
  Future<void> refresh() async {
    await fetchSliders();
    await fetchStats();
  }
}
