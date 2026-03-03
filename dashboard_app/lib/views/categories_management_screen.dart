import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';
import '../services/image_service.dart';

class CategoriesManagementScreen extends StatelessWidget {
  CategoriesManagementScreen({super.key});

  final CategoryController controller = Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الفئات'),
        backgroundColor: Get.theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.loadCategories(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.categories.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        if (controller.categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('لا توجد فئات', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => controller.loadCategories(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: controller.filteredCategories.length,
            itemBuilder: (context, index) {
              final category = controller.filteredCategories[index];
              return _CategoryCard(
                category: category,
                onEdit: () => _showEditCategoryDialog(category),
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _showEditCategoryDialog(CategoryModel category) async {
    final titleController = TextEditingController(text: category.title);
    File? newImageFile;
    bool clearImage = false;

    await Get.dialog(
      AlertDialog(
        title: Text('تعديل الفئة'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'اسم الفئة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('صورة الفئة (تظهر في التطبيق)', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: newImageFile != null
                            ? Image.file(newImageFile!, width: 80, height: 80, fit: BoxFit.cover)
                            : (clearImage
                                ? _placeholderBox()
                                : (category.image.isNotEmpty
                                    ? Image.network(
                                        category.image,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _placeholderBox(),
                                      )
                                    : _placeholderBox())),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picker = ImagePicker();
                              final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
                              if (picked != null) {
                                setState(() {
                                  newImageFile = File(picked.path);
                                  clearImage = false;
                                });
                              }
                            },
                            icon: Icon(Icons.photo_library, size: 20),
                            label: Text('اختيار صورة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          if (category.image.isNotEmpty || newImageFile != null)
                            TextButton(
                              onPressed: () => setState(() {
                                newImageFile = null;
                                clearImage = true;
                              }),
                              child: Text('إزالة الصورة', style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              if (newTitle.isEmpty) {
                Get.snackbar('تنبيه', 'أدخل اسم الفئة');
                return;
              }
              Get.back();
              String imageUrl = category.image;
              if (clearImage) {
                imageUrl = '';
              } else if (newImageFile != null) {
                final url = await ImageService.uploadCategoryImage(newImageFile!, category.originalId);
                if (url != null) imageUrl = url;
              }
              await controller.updateCategory(category.id, {
                'title': newTitle,
                'image': imageUrl,
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            child: Text('حفظ'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Widget _placeholderBox() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;

  const _CategoryCard({required this.category, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: category.image.isNotEmpty
              ? Image.network(
                  category.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        title: Text(category.title, style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('ID: ${category.originalId}', style: TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: Colors.deepPurple),
          onPressed: onEdit,
          tooltip: 'تعديل الصورة والاسم',
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey[300],
      child: Icon(Icons.category, color: Colors.grey[600]),
    );
  }
}
