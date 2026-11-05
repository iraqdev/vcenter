import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';
import '../services/image_service.dart';
import '../utils/dashboard_dialog.dart';

class CategoriesManagementScreen extends StatelessWidget {
  CategoriesManagementScreen({super.key});

  final CategoryController controller = Get.find<CategoryController>();

  int _nextOriginalId() {
    if (controller.categories.isEmpty) return 1;
    var maxId = 0;
    for (final c in controller.categories) {
      if (c.originalId > maxId) maxId = c.originalId;
    }
    return maxId + 1;
  }

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
            icon: Icon(Icons.add),
            tooltip: 'إضافة فئة',
            onPressed: _showAddCategoryDialog,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.loadCategories(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: Get.theme.primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('إضافة فئة'),
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
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _showAddCategoryDialog,
                  icon: Icon(Icons.add),
                  label: Text('إضافة فئة جديدة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
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

  Future<void> _showAddCategoryDialog() async {
    final titleController = TextEditingController();
    File? imageFile;
    bool isSaving = false;
    String? formError;

    await Get.dialog(
      StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('إضافة فئة جديدة'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'اسم الفئة *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (formError != null) {
                        setDialogState(() => formError = null);
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  Text(
                    'صورة الفئة (تظهر في التطبيق)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageFile != null
                            ? Image.file(
                                imageFile!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : _placeholderBox(),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final picker = ImagePicker();
                                    final XFile? picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        imageFile = File(picked.path);
                                        formError = null;
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
                          if (imageFile != null)
                            TextButton(
                              onPressed: isSaving
                                  ? null
                                  : () => setDialogState(() => imageFile = null),
                              child: Text(
                                'إزالة الصورة',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (formError != null) ...[
                    SizedBox(height: 12),
                    Text(
                      formError!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newTitle = titleController.text.trim();
                        if (newTitle.isEmpty) {
                          setDialogState(
                            () => formError = 'أدخل اسم الفئة',
                          );
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          formError = null;
                        });

                        try {
                          final originalId = _nextOriginalId();
                          String imageUrl = '';
                          if (imageFile != null) {
                            final url = await ImageService.uploadCategoryImage(
                              imageFile!,
                              originalId,
                            );
                            if (url != null) imageUrl = url;
                          }

                          final category = CategoryModel(
                            id: '',
                            title: newTitle,
                            image: imageUrl,
                            originalId: originalId,
                            active: true,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          final id = await controller.addCategory(category);
                          if (!dialogContext.mounted) return;

                          if (id != null) {
                            Navigator.of(dialogContext).pop();
                          } else {
                            setDialogState(() {
                              isSaving = false;
                              formError = 'فشل إضافة الفئة. حاول مرة أخرى';
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            formError = 'فشل الإضافة: $e';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('إضافة'),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );

    titleController.dispose();
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
            onPressed: closeDashboardDialog,
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newTitle = titleController.text.trim();
              if (newTitle.isEmpty) {
                Get.snackbar('تنبيه', 'أدخل اسم الفئة');
                return;
              }
              closeDashboardDialog();
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
