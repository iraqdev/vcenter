import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product_model.dart';
import '../controllers/category_controller.dart';
import '../controllers/subcategory_controller.dart';
import '../controllers/branch_controller.dart';
import '../services/image_service.dart';

class ProductEditDialog extends StatefulWidget {
  final ProductModel? product;
  final Function(ProductModel) onSave;

  const ProductEditDialog({
    super.key,
    required this.product,
    required this.onSave,
  });

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _subCategoryController = TextEditingController();
  bool _isActive = true;
  
  // متغير لتتبع الفئة الفرعية المختارة
  int? _selectedSubCategory;
  
  // متغير لتتبع الفرع المختار (مطلوب عند إضافة منتج جديد)
  String? _selectedBranch;
  
  // متغيرات إدارة الصور
  List<File> _selectedImages = [];
  bool _isUploadingImages = false;
  
  final CategoryController categoryController = Get.find<CategoryController>();
  final SubCategoryController subCategoryController = Get.find<SubCategoryController>();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.title;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _imageUrlController.text = widget.product!.image;
      _categoryController.text = widget.product!.category.toString();
      _brandController.text = widget.product!.brand ?? '';
      _modelController.text = widget.product!.model ?? '';
      _subCategoryController.text = widget.product!.subCategory?.toString() ?? '';
      _selectedSubCategory = widget.product!.subCategory;
      _selectedBranch = widget.product!.branch;
      _isActive = widget.product!.active;
    } else {
      // عند إضافة منتج جديد: استخدم الفرع الحالي من الداش (إن لم يكن المسؤول)
      final branchController = Get.find<BranchController>();
      final currentBranch = branchController.selectedBranch.value;
      _selectedBranch = currentBranch == 'المسؤول' ? null : currentBranch;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // العنوان
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Get.theme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.product == null ? Icons.add : Icons.edit,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    widget.product == null ? 'إضافة منتج جديد' : 'تعديل المنتج',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // النموذج
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المنتج
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'اسم المنتج *',
                          prefixIcon: Icon(Icons.shopping_bag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال اسم المنتج';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      
                      // وصف المنتج
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'وصف المنتج',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 20),
                      
                      // السعر
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'السعر (د.ع) *',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال السعر';
                          }
                          if (int.tryParse(value) == null) {
                            return 'يرجى إدخال سعر صحيح';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      
                      // الفئة
                      DropdownButtonFormField<int>(
                        value: widget.product?.category ?? 0,
                        decoration: InputDecoration(
                          labelText: 'الفئة *',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: [
                          DropdownMenuItem<int>(
                            value: 0,
                            child: Text('اختر الفئة'),
                          ),
                          ...categoryController.categories.map((category) =>
                            DropdownMenuItem<int>(
                              value: category.originalId,
                              child: Text(category.title),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            print('🔄 ProductEditDialog - تم تغيير الفئة الرئيسية إلى: $value');
                            _categoryController.text = value.toString();
                            // تحديث الفئات الفرعية عند تغيير الفئة الرئيسية
                            subCategoryController.setSelectedCategory(value);
                            // إعادة تعيين الفئة الفرعية المختارة
                            setState(() {
                              _selectedSubCategory = null;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value == 0) {
                            return 'يرجى اختيار الفئة';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      
                      // العلامة التجارية
                      TextFormField(
                        controller: _brandController,
                        decoration: InputDecoration(
                          labelText: 'العلامة التجارية',
                          hintText: 'مثال: Apple, Samsung',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.branding_watermark),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // الموديل
                      TextFormField(
                        controller: _modelController,
                        decoration: InputDecoration(
                          labelText: 'الموديل',
                          hintText: 'مثال: iPhone 14, Galaxy S23',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.phone_android),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // الفئة الفرعية
                      Obx(() {
                        final selectedCategory = int.tryParse(_categoryController.text) ?? 0;
                        final subCategories = subCategoryController.getSubCategoriesByCategory(selectedCategory);
                        
                        print('🔍 ProductEditDialog - الفئة المختارة: $selectedCategory');
                        print('🔍 ProductEditDialog - عدد الفئات الفرعية: ${subCategories.length}');
                        
                        // إنشاء فئات فرعية افتراضية إذا لم توجد فئات فرعية
                        List<Map<String, dynamic>> defaultSubCategories = [];
                        if (subCategories.isEmpty && selectedCategory != 0) {
                          print('⚠️ ProductEditDialog - لا توجد فئات فرعية، إنشاء فئات افتراضية');
                          defaultSubCategories = [
                            {'id': 1, 'title': 'شاشة'},
                            {'id': 2, 'title': 'بطارية'},
                            {'id': 3, 'title': 'فلات شحن'},
                            {'id': 4, 'title': 'ظهر'},
                            {'id': 5, 'title': 'كاميرا امامية'},
                            {'id': 6, 'title': 'كاميرا خلفية'},
                            {'id': 7, 'title': 'شريط'},
                            {'id': 8, 'title': 'فلات بور'},
                            {'id': 9, 'title': 'شاصي'},
                            {'id': 10, 'title': 'سماعة علوية'},
                          ];
                        }
                        
                        return DropdownButtonFormField<int>(
                          value: _selectedSubCategory,
                          decoration: InputDecoration(
                            labelText: 'الفئة الفرعية',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: subCategories.isNotEmpty 
                            ? subCategories.map((subCategory) {
                                return DropdownMenuItem<int>(
                                  value: subCategory.originalId,
                                  child: Text(subCategory.title),
                                );
                              }).toList()
                            : defaultSubCategories.map((subCategory) {
                                return DropdownMenuItem<int>(
                                  value: subCategory['id'],
                                  child: Text(subCategory['title']),
                                );
                              }).toList(),
                          onChanged: (int? value) {
                            setState(() {
                              _selectedSubCategory = value;
                            });
                            print('🔄 ProductEditDialog - تم اختيار الفئة الفرعية: $value');
                          },
                          validator: (value) {
                            if (selectedCategory == 0) {
                              return 'يرجى اختيار الفئة الرئيسية أولاً';
                            }
                            return null;
                          },
                        );
                      }),
                      SizedBox(height: 20),
                      
                      // اختيار الفرع (مطلوب - يحدد أين يظهر هذا المنتج)
                      DropdownButtonFormField<String>(
                        value: _selectedBranch,
                        decoration: InputDecoration(
                          labelText: 'الفرع *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.store),
                        ),
                        items: ['الغزالية', 'الزعفرانية', 'الاعظمية', 'العراق']
                            .map((String branch) {
                          return DropdownMenuItem<String>(
                            value: branch,
                            child: Text(branch),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _selectedBranch = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى اختيار الفرع الذي سيظهر فيه المنتج';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      
                      // قسم الصورة
                      Text(
                        'صورة المنتج',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // معاينة الصورة
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _buildImagePreview(),
                      ),
                      SizedBox(height: 12),
                      
                      // أزرار إدارة الصورة
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showImagePickerOptions,
                              icon: Icon(Icons.add_photo_alternate),
                              label: Text('اختيار صورة'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedImages.clear();
                                _imageUrlController.clear();
                              });
                            },
                              icon: Icon(Icons.delete),
                              label: Text('حذف'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      
                      // رابط الصورة (للمستخدمين المتقدمين)
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'رابط الصورة (اختياري)',
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          helperText: 'يمكنك إدخال رابط صورة مباشرة بدلاً من اختيار صورة من الهاتف',
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      
                      // حالة التفعيل
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.toggle_on, color: Colors.deepPurple),
                            SizedBox(width: 10),
                            Text(
                              'حالة المنتج',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Spacer(),
                            Switch(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                              activeColor: Colors.green,
                              inactiveThumbColor: Colors.red,
                            ),
                            Text(
                              _isActive ? 'نشط' : 'غير نشط',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _isActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                      
                    ],
                  ),
                ),
              ),
            ),
            
            // أزرار التحكم
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey),
                      ),
                      child: Text('إلغاء'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploadingImages ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Get.theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isUploadingImages
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('جاري رفع الصور...'),
                              ],
                            )
                          : Text(
                              widget.product == null ? 'إضافة المنتج' : 'حفظ التعديلات',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // اختيار عدة صور من المعرض
  Future<void> _pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في اختيار الصور: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // اختيار صورة واحدة من المعرض
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في اختيار الصورة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // اختيار صورة من الكاميرا
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في التقاط الصورة: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // عرض خيارات اختيار الصورة
  void _showImagePickerOptions() {
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
            Text(
              'اختر مصدر الصورة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'صورة واحدة',
                  onTap: () {
                    Get.back();
                    _pickImageFromGallery();
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library_outlined,
                  label: 'عدة صور',
                  onTap: () {
                    Get.back();
                    _pickMultipleImagesFromGallery();
                  },
                ),
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'الكاميرا',
                  onTap: () {
                    Get.back();
                    _pickImageFromCamera();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_selectedImages.isNotEmpty || (_imageUrlController.text.isNotEmpty && ImageService.isValidImageUrl(_imageUrlController.text)))
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImages.clear();
                    _imageUrlController.clear();
                  });
                  Get.back();
                },
                child: Text(
                  'حذف جميع الصور',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  // معاينة الصور
  Widget _buildImagePreview() {
    // إذا تم اختيار صور جديدة
    if (_selectedImages.isNotEmpty) {
      return _buildSelectedImagesPreview();
    }
    
    // إذا كان هناك رابط صورة موجود
    if (_imageUrlController.text.isNotEmpty && ImageService.isValidImageUrl(_imageUrlController.text)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          _imageUrlController.text,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          errorBuilder: (context, error, stackTrace) {
            return _buildNoImagePlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    }
    
    // إذا لم تكن هناك صور
    return _buildNoImagePlaceholder();
  }

  // معاينة الصور المختارة
  Widget _buildSelectedImagesPreview() {
    return Container(
      height: 200,
      child: Column(
        children: [
          // عرض الصور في شبكة
          Expanded(
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // عداد الصور
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_selectedImages.length} صورة مختارة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 50,
            color: Colors.grey[400],
          ),
          SizedBox(height: 8),
          Text(
            'لا توجد صورة',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'اضغط على "اختيار صورة" لإضافة صورة',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      String imageUrl = _imageUrlController.text.trim();
      List<String> images = [];
      
      // إذا تم اختيار صور جديدة، قم برفعها
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });

        try {
          final uploadedUrls = await ImageService.uploadMultipleProductImages(
            _selectedImages,
            widget.product?.images, // الصور القديمة للحذف
          );
          
          if (uploadedUrls.isNotEmpty) {
            images = uploadedUrls;
            imageUrl = uploadedUrls.first; // الصورة الرئيسية
          } else {
            Get.snackbar(
              'خطأ',
              'فشل في رفع الصور',
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            setState(() {
              _isUploadingImages = false;
            });
            return;
          }
        } catch (e) {
          Get.snackbar(
            'خطأ',
            'فشل في رفع الصور: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          setState(() {
            _isUploadingImages = false;
          });
          return;
        }

        setState(() {
          _isUploadingImages = false;
        });
      } else if (imageUrl.isNotEmpty) {
        // إذا كان هناك رابط صورة واحد فقط
        images = [imageUrl];
      }

      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final product = ProductModel(
        id: widget.product?.id ?? newId,
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: int.parse(_priceController.text),
        image: imageUrl,
        images: images,
        category: int.parse(_categoryController.text),
        active: _isActive,
        originalId: widget.product?.originalId ?? DateTime.now().millisecondsSinceEpoch,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        branch: _selectedBranch,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        subCategory: _selectedSubCategory,
      );

      widget.onSave(product);
      Get.back(); // إغلاق الدايلوغ بعد الحفظ
    }
  }
}
