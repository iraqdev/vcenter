import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/slider_model.dart';
import '../services/firebase_storage_service.dart';

class SliderEditDialog extends StatefulWidget {
  final SliderModel? slider;
  final Function(SliderModel) onSave;

  const SliderEditDialog({
    super.key,
    this.slider,
    required this.onSave,
  });

  @override
  State<SliderEditDialog> createState() => _SliderEditDialogState();
}

class _SliderEditDialogState extends State<SliderEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  bool _isActive = true;
  bool _isUploading = false;
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.slider != null) {
      _titleController.text = widget.slider!.title;
      _currentImageUrl = widget.slider!.image;
      _isActive = widget.slider!.active;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // اختيار صورة من المعرض
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _currentImageUrl = null;
        });
      }
    } catch (e) {
      print('❌ خطأ في اختيار الصورة: $e');
      Get.snackbar('خطأ', 'فشل في اختيار الصورة');
    }
  }

  // التقاط صورة من الكاميرا
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _currentImageUrl = null;
        });
      }
    } catch (e) {
      print('❌ خطأ في التقاط الصورة: $e');
      Get.snackbar('خطأ', 'فشل في التقاط الصورة');
    }
  }

  // عرض خيارات اختيار الصورة
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
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
                  label: 'المعرض',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromGallery();
                  },
                ),
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'الكاميرا',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
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
          color: Get.theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Get.theme.primaryColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Get.theme.primaryColor,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Get.theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // حفظ العرض
  Future<void> _saveSlider() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImage == null && _currentImageUrl == null) {
      Get.snackbar('خطأ', 'الرجاء اختيار صورة للعرض');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl = _currentImageUrl;
      
      // إذا تم اختيار صورة جديدة، ارفعها إلى Firebase Storage
      if (_selectedImage != null) {
        final sliderId = widget.slider?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await FirebaseStorageService.uploadSliderImage(_selectedImage!, sliderId);
        
        if (imageUrl == null) {
          Get.snackbar('خطأ', 'فشل في رفع الصورة');
          setState(() {
            _isUploading = false;
          });
          return;
        }
      }

      // إنشاء نموذج العرض
      final slider = SliderModel(
        id: widget.slider?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        image: imageUrl!,
        active: _isActive,
        originalId: widget.slider?.originalId,
        createdAt: widget.slider?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ العرض
      widget.onSave(slider);
      
      Get.snackbar('نجح', 'تم حفظ العرض بنجاح');
      Navigator.of(context).pop();
      
    } catch (e) {
      print('❌ خطأ في حفظ العرض: $e');
      Get.snackbar('خطأ', 'فشل في حفظ العرض');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // العنوان
                  _buildHeader(),
                  SizedBox(height: 24),
                  
                  // حقل العنوان
                  _buildTitleField(),
                  SizedBox(height: 20),
                  
                  // قسم الصورة
                  _buildImageSection(),
                  SizedBox(height: 20),
                  
                  // حالة العرض
                  _buildStatusSwitch(),
                  SizedBox(height: 24),
                  
                  // أزرار الإجراءات
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Get.theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.image,
            color: Get.theme.primaryColor,
            size: 24,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.slider == null ? 'إضافة عرض جديد' : 'تعديل العرض',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Get.theme.primaryColor,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'عنوان العرض',
        hintText: 'أدخل عنوان العرض',
        prefixIcon: Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'الرجاء إدخال عنوان العرض';
        }
        return null;
      },
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صورة العرض',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        
        // زر اختيار الصورة
        GestureDetector(
          onTap: _showImagePickerOptions,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              color: Colors.grey[50],
            ),
            child: _selectedImage != null
                ? _buildSelectedImagePreview()
                : _currentImageUrl != null
                    ? _buildCurrentImagePreview()
                    : _buildImagePickerPlaceholder(),
          ),
        ),
        
        SizedBox(height: 8),
        Text(
          'اضغط لاختيار صورة من المعرض أو التقاط صورة جديدة',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        _selectedImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildCurrentImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: _currentImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8),
              Text(
                'خطأ في تحميل الصورة',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
        SizedBox(height: 8),
        Text(
          'اضغط لاختيار صورة',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? Icons.visibility : Icons.visibility_off,
            color: _isActive ? Colors.green : Colors.grey,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة العرض',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _isActive ? 'نشط - مرئي للمستخدمين' : 'مخفي - غير مرئي للمستخدمين',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() {
                _isActive = value;
              });
            },
            activeColor: Get.theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('إلغاء'),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isUploading ? null : _saveSlider,
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isUploading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('جاري الحفظ...'),
                    ],
                  )
                : Text('حفظ'),
          ),
        ),
      ],
    );
  }
}
