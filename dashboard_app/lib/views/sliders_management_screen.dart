import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/slider_controller.dart';
import '../models/slider_model.dart';
import '../widgets/slider_card.dart';
import '../widgets/slider_edit_dialog.dart';

class SlidersManagementScreen extends StatelessWidget {
  SlidersManagementScreen({super.key});

  final SliderController sliderController = Get.put(SliderController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSliderDialog(),
        backgroundColor: Get.theme.primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('إضافة عرض'),
      ),
      appBar: AppBar(
        title: Text('إدارة العروض الترويجية'),
        backgroundColor: Get.theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر البحث
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          // زر الفلترة
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          // زر إضافة عرض جديد
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddSliderDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط الإحصائيات
          _buildStatsBar(),
          
          // شريط البحث والفلترة
          _buildSearchAndFilterBar(),
          
          // قائمة العروض
          Expanded(
            child: Obx(() {
              print('🔄 SlidersManagementScreen: isLoading=${sliderController.isLoading.value}');
              print('🔄 SlidersManagementScreen: errorMessage=${sliderController.errorMessage.value}');
              print('🔄 SlidersManagementScreen: filteredSliders.length=${sliderController.filteredSliders.length}');
              
              if (sliderController.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (sliderController.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16),
                      Text(
                        sliderController.errorMessage.value,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => sliderController.refresh(),
                        child: Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }
              
              if (sliderController.filteredSliders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد عروض',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'اضغط على + لإضافة عرض جديد',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => sliderController.fetchSliders(),
                        child: Text('تحديث'),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async => sliderController.refresh(),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: sliderController.filteredSliders.length,
                  itemBuilder: (context, index) {
                    final slider = sliderController.filteredSliders[index];
                    return SliderCard(
                      slider: slider,
                      onEdit: () => _showEditSliderDialog(slider),
                      onToggleStatus: () => _toggleSliderStatus(slider),
                      onDelete: () => _showDeleteConfirmation(slider),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // شريط الإحصائيات
  Widget _buildStatsBar() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Obx(() {
        final stats = sliderController.stats;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.image,
              label: 'إجمالي العروض',
              value: '${stats['total'] ?? 0}',
              color: Colors.white,
            ),
            _buildStatItem(
              icon: Icons.visibility,
              label: 'عروض نشطة',
              value: '${stats['active'] ?? 0}',
              color: Colors.green[300]!,
            ),
            _buildStatItem(
              icon: Icons.visibility_off,
              label: 'عروض مخفية',
              value: '${stats['inactive'] ?? 0}',
              color: Colors.orange[300]!,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  // شريط البحث والفلترة
  Widget _buildSearchAndFilterBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // حقل البحث
          Expanded(
            child: TextField(
              onChanged: (value) => sliderController.updateSearchQuery(value),
              decoration: InputDecoration(
                hintText: 'البحث في العروض...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          SizedBox(width: 12),
          
          // فلتر الحالة
          Obx(() {
            return Container(
              width: 120, // عرض محدد
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: sliderController.selectedStatus.value,
                items: [
                  DropdownMenuItem(value: 'all', child: Text('جميع العروض')),
                  DropdownMenuItem(value: 'active', child: Text('نشطة')),
                  DropdownMenuItem(value: 'inactive', child: Text('مخفية')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    sliderController.updateStatusFilter(value);
                  }
                },
                underline: SizedBox(), // إزالة الخط السفلي
                isExpanded: true,
              ),
            );
          }),
        ],
      ),
    );
  }

  // نافذة إضافة عرض جديد
  void _showAddSliderDialog() {
    Get.dialog(
      SliderEditDialog(
        slider: null,
        onSave: (slider) => sliderController.addSlider(slider),
      ),
      barrierDismissible: true,
    );
  }

  // نافذة تعديل عرض
  void _showEditSliderDialog(SliderModel slider) {
    Get.dialog(
      SliderEditDialog(
        slider: slider,
        onSave: (updatedSlider) => sliderController.updateSlider(slider.id, updatedSlider),
      ),
      barrierDismissible: true,
    );
  }

  // تبديل حالة العرض
  void _toggleSliderStatus(SliderModel slider) {
    sliderController.toggleSliderStatus(slider.id, !slider.active);
  }

  // تأكيد الحذف
  void _showDeleteConfirmation(SliderModel slider) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف العرض "${slider.title}"؟\n\nهذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              sliderController.deleteSlider(slider.id);
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  // نافذة البحث المتقدم
  void _showSearchDialog() {
    // يمكن إضافة بحث متقدم هنا
    Get.snackbar('معلومة', 'البحث المتقدم قريباً');
  }

  // نافذة الفلترة المتقدمة
  void _showFilterDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('فلترة العروض'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ترتيب حسب:'),
            SizedBox(height: 16),
            Obx(() {
              return Column(
                children: [
                  RadioListTile<String>(
                    title: Text('تاريخ الإنشاء'),
                    value: 'createdAt',
                    groupValue: sliderController.sortBy.value,
                    onChanged: (value) {
                      if (value != null) {
                        sliderController.updateSorting(value, sliderController.sortDescending.value);
                        Get.back();
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('العنوان'),
                    value: 'title',
                    groupValue: sliderController.sortBy.value,
                    onChanged: (value) {
                      if (value != null) {
                        sliderController.updateSorting(value, sliderController.sortDescending.value);
                        Get.back();
                      }
                    },
                  ),
                ],
              );
            }),
            SizedBox(height: 16),
            Obx(() {
              return SwitchListTile(
                title: Text('ترتيب تنازلي'),
                value: sliderController.sortDescending.value,
                onChanged: (value) {
                  sliderController.updateSorting(sliderController.sortBy.value, value);
                  Get.back();
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => sliderController.clearFilters(),
            child: Text('مسح الفلاتر'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
