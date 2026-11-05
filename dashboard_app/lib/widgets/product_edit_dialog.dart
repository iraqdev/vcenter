import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/product_model.dart';
import '../controllers/category_controller.dart';
import '../controllers/subcategory_controller.dart';
import '../controllers/branch_controller.dart';
import '../services/image_service.dart';
import '../utils/dashboard_dialog.dart';

class ProductEditDialog extends StatefulWidget {
  final ProductModel? product;
  final Future<bool> Function(ProductModel) onSave;

  const ProductEditDialog({
    super.key,
    required this.product,
    required this.onSave,
  });

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  static const List<String> _validBranches = [
    'all',
    'الغزالية',
    'الزعفرانية',
    'الاعظمية',
    'العراق',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _customerPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _subCategoryController = TextEditingController();
  bool _isActive = true;
  bool _showForStore = true;
  bool _showForCustomer = true;
  int? _selectedCategory;
  int? _selectedSubCategory;
  String? _selectedBranch;
  String? _formError;
  
  // متغيرات إدارة الصور
  List<File> _selectedImages = [];
  bool _isUploadingImages = false;
  bool _isSavingProduct = false;
  
  final CategoryController categoryController = Get.find<CategoryController>();
  final SubCategoryController subCategoryController = Get.find<SubCategoryController>();
  final ImagePicker _imagePicker = ImagePicker();

  String? _normalizeBranch(String? branch) {
    if (branch == null || branch.trim().isEmpty) return 'all';
    final b = branch.trim();
    if (_validBranches.contains(b)) return b;
    return 'all';
  }

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.title;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      if (widget.product!.customerPrice != null) {
        _customerPriceController.text = widget.product!.customerPrice.toString();
      } else if (widget.product!.showForCustomer) {
        _customerPriceController.text =
            widget.product!.effectiveCustomerPrice.toString();
      }
      _imageUrlController.text = widget.product!.image;
      _selectedCategory = widget.product!.category == 0
          ? null
          : widget.product!.category;
      _categoryController.text = (_selectedCategory ?? 0).toString();
      _brandController.text = widget.product!.brand ?? '';
      _modelController.text = widget.product!.model ?? '';
      _subCategoryController.text = widget.product!.subCategory?.toString() ?? '';
      _selectedSubCategory = widget.product!.subCategory;
      _selectedBranch = _normalizeBranch(widget.product!.branch);
      _isActive = widget.product!.active;
      _showForStore = widget.product!.showForStore;
      _showForCustomer = widget.product!.showForCustomer;
      if (_selectedCategory != null) {
        subCategoryController.setSelectedCategory(_selectedCategory!);
      }
    } else {
      // عند إضافة منتج جديد: استخدم الفرع الحالي من الداش (إن لم يكن المسؤول)
      final branchController = Get.find<BranchController>();
      final currentBranch = branchController.selectedBranch.value;
      _selectedBranch = currentBranch == 'المسؤول'
          ? 'all'
          : _normalizeBranch(currentBranch);
      // افتراضي للمنتجات الجديدة: متجر + زبون
      _showForStore = true;
      _showForCustomer = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _customerPriceController.dispose();
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
                      
                      // ظهور المنتج: متجر / زبون
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'عرض المنتج لـ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('المتاجر'),
                              subtitle: Text('يظهر لأصحاب المحلات'),
                              secondary: Icon(Icons.store, color: Colors.deepPurple),
                              value: _showForStore,
                              activeColor: Colors.deepPurple,
                              onChanged: (value) {
                                setState(() {
                                  _showForStore = value;
                                  _formError = null;
                                });
                              },
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('الزبائن'),
                              subtitle: Text('يظهر للمستخدمين العاديين (زبون)'),
                              secondary: Icon(Icons.person, color: Colors.teal),
                              value: _showForCustomer,
                              activeColor: Colors.teal,
                              onChanged: (value) {
                                setState(() {
                                  _showForCustomer = value;
                                  _formError = null;
                                  // عند التفعيل وغياب سعر زبون: ضع الافتراضي للتعديل
                                  if (value &&
                                      _customerPriceController.text.trim().isEmpty) {
                                    final base = _parsePrice(_priceController.text) ??
                                        widget.product?.price ??
                                        0;
                                    _customerPriceController.text =
                                        (base + 4000).toString();
                                  }
                                });
                              },
                            ),
                            if (!_showForStore && !_showForCustomer)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'يجب تفعيل المتجر أو الزبون على الأقل',
                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // سعر المتجر
                      TextFormField(
                        controller: _priceController,
                        enabled: _showForStore,
                        decoration: InputDecoration(
                          labelText: _showForStore ? 'سعر المتجر (د.ع) *' : 'سعر المتجر (د.ع)',
                          prefixIcon: Icon(Icons.store),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          helperText: _showForStore
                              ? null
                              : 'معطّل لأن عرض المتجر غير مفعّل',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (!_showForStore) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال سعر المتجر';
                          }
                          if (_parsePrice(value) == null) {
                            return 'يرجى إدخال سعر صحيح';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // سعر الزبون
                      TextFormField(
                        controller: _customerPriceController,
                        enabled: _showForCustomer,
                        decoration: InputDecoration(
                          labelText: _showForCustomer ? 'سعر الزبون (د.ع) *' : 'سعر الزبون (د.ع)',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          helperText: _showForCustomer
                              ? 'يُعرض للزبون كما هو بدون إضافة'
                              : 'معطّل لأن عرض الزبون غير مفعّل',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (!_showForCustomer) return null;
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال سعر الزبون';
                          }
                          if (_parsePrice(value) == null) {
                            return 'يرجى إدخال سعر صحيح';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      
                      // الفئة
                      Obx(() {
                        final categoryItems = categoryController.categories
                            .map((category) => DropdownMenuItem<int>(
                                  value: category.originalId,
                                  child: Text(category.title),
                                ))
                            .toList();
                        final categoryIds =
                            categoryItems.map((e) => e.value).toSet();
                        final safeCategory =
                            categoryIds.contains(_selectedCategory)
                                ? _selectedCategory
                                : null;

                        return DropdownButtonFormField<int>(
                          value: safeCategory,
                          decoration: InputDecoration(
                            labelText: 'الفئة *',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: categoryItems,
                          onChanged: (value) {
                            if (value != null) {
                              print('🔄 ProductEditDialog - تم تغيير الفئة الرئيسية إلى: $value');
                              _categoryController.text = value.toString();
                              subCategoryController.setSelectedCategory(value);
                              setState(() {
                                _selectedCategory = value;
                                _selectedSubCategory = null;
                                _formError = null;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value == 0) {
                              return 'يرجى اختيار الفئة';
                            }
                            return null;
                          },
                        );
                      }),
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
                        
                        final items = subCategories.isNotEmpty
                            ? subCategories
                                .map((subCategory) => DropdownMenuItem<int>(
                                      value: subCategory.originalId,
                                      child: Text(subCategory.title),
                                    ))
                                .toList()
                            : defaultSubCategories
                                .map((subCategory) => DropdownMenuItem<int>(
                                      value: subCategory['id'] as int,
                                      child: Text(subCategory['title'] as String),
                                    ))
                                .toList();
                        final itemValues = items.map((e) => e.value).toSet();
                        final safeSubCategory =
                            itemValues.contains(_selectedSubCategory)
                                ? _selectedSubCategory
                                : null;

                        return DropdownButtonFormField<int>(
                          value: safeSubCategory,
                          decoration: InputDecoration(
                            labelText: 'الفئة الفرعية',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: items,
                          onChanged: (int? value) {
                            setState(() {
                              _selectedSubCategory = value;
                            });
                            print('🔄 ProductEditDialog - تم اختيار الفئة الفرعية: $value');
                          },
                          validator: (value) {
                            if (selectedCategory == 0 && _selectedCategory == null) {
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
                          helperText: 'اختر "جميع الفروع" لعرض المنتج في كل الفروع',
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: 'all',
                            child: Row(
                              children: [
                                Icon(Icons.public, size: 18, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('جميع الفروع', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                          ),
                          ...['الغزالية', 'الزعفرانية', 'الاعظمية', 'العراق'].map((String branch) {
                            return DropdownMenuItem<String>(
                              value: branch,
                              child: Text(branch),
                            );
                          }),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedBranch = value;
                            _formError = null;
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

                      if (_formError != null) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _formError!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ],
                      
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
                      onPressed: _isSavingProduct ? null : closeDashboardDialog,
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
                      onPressed: (_isUploadingImages || _isSavingProduct) ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Get.theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: (_isUploadingImages || _isSavingProduct)
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
                                Text(_isUploadingImages ? 'جاري رفع الصور...' : 'جاري الحفظ...'),
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

  /// يقبل أرقامًا مع مسافات أو فواصل آلاف.
  int? _parsePrice(String? value) {
    if (value == null) return null;
    final cleaned = value
        .trim()
        .replaceAll(',', '')
        .replaceAll('،', '')
        .replaceAll(' ', '')
        .replaceAll('\u00A0', '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  void _setFormError(String message) {
    if (!mounted) return;
    setState(() => _formError = message);
  }

  void _saveProduct() async {
    setState(() => _formError = null);

    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) {
      _setFormError('يرجى إكمال الحقول المطلوبة (الأسعار، الفئة، الفرع)');
      return;
    }
    if (!_showForStore && !_showForCustomer) {
      _setFormError('يجب تفعيل العرض للمتجر أو للزبون على الأقل');
      return;
    }
    if (_isSavingProduct) return;
    _isSavingProduct = true;
    if (mounted) setState(() {});

    try {
      String imageUrl = _imageUrlController.text.trim();
      List<String> images = [];

      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploadingImages = true;
        });

        try {
          final uploadedUrls = await ImageService.uploadMultipleProductImages(
            _selectedImages,
            widget.product?.images,
          );

          if (uploadedUrls.isNotEmpty) {
            images = uploadedUrls;
            imageUrl = uploadedUrls.first;
          } else {
            _setFormError('فشل في رفع الصور');
            return;
          }
        } catch (e) {
          _setFormError('فشل في رفع الصور: $e');
          return;
        } finally {
          if (mounted) {
            setState(() {
              _isUploadingImages = false;
            });
          }
        }
      } else if (imageUrl.isNotEmpty) {
        images = [imageUrl];
      } else if (widget.product != null) {
        images = widget.product!.images;
        imageUrl = widget.product!.image;
      }

      final parsedStorePrice = _parsePrice(_priceController.text);
      final parsedCustomerPrice = _parsePrice(_customerPriceController.text);
      final storePrice = parsedStorePrice ?? widget.product?.price ?? 0;
      final customerPrice = _showForCustomer ? parsedCustomerPrice : null;

      if (_showForCustomer && customerPrice == null) {
        _setFormError('يرجى إدخال سعر زبون صحيح');
        return;
      }
      if (_showForStore && parsedStorePrice == null) {
        _setFormError('يرجى إدخال سعر متجر صحيح');
        return;
      }

      final category = _selectedCategory ??
          int.tryParse(_categoryController.text.trim()) ??
          widget.product?.category ??
          0;
      if (category == 0) {
        _setFormError('يرجى اختيار الفئة');
        return;
      }

      final branch = _normalizeBranch(_selectedBranch);

      final docId = widget.product?.id ??
          FirebaseFirestore.instance.collection('products').doc().id;
      final product = ProductModel(
        id: docId,
        title: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: storePrice,
        customerPrice: customerPrice,
        image: imageUrl,
        images: images.isNotEmpty
            ? images
            : (widget.product?.images ?? const <String>[]),
        category: category,
        active: _isActive,
        originalId: widget.product?.originalId ??
            DateTime.now().microsecondsSinceEpoch,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        branch: branch,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        subCategory: _selectedSubCategory,
        posLink: widget.product?.posLink,
        stock: widget.product?.stock,
        branchMessages: widget.product?.branchMessages,
        showForStore: _showForStore,
        showForCustomer: _showForCustomer,
      );

      final success = await widget.onSave(product);
      if (!mounted) return;

      if (success) {
        closeDashboardDialog();
        Future.delayed(const Duration(milliseconds: 150), () {
          Get.snackbar(
            'تم',
            widget.product == null
                ? 'تم إضافة المنتج بنجاح'
                : 'تم حفظ تعديلات المنتج',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        });
      } else {
        _setFormError('فشل حفظ المنتج في قاعدة البيانات. حاول مرة أخرى');
      }
    } catch (e) {
      _setFormError('فشل الحفظ: $e');
    } finally {
      _isSavingProduct = false;
      if (mounted) setState(() {});
    }
  }
}
