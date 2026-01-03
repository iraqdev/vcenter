import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';

class UserEditDialog extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onSave;

  const UserEditDialog({
    super.key,
    required this.user,
    required this.onSave,
  });

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController cityController;
  late TextEditingController addressController;
  late TextEditingController nearController;
  late TextEditingController pointsController;
  late bool isActive;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    phoneController = TextEditingController(text: widget.user.phone);
    cityController = TextEditingController(text: widget.user.city);
    addressController = TextEditingController(text: widget.user.address);
    nearController = TextEditingController(text: widget.user.near);
    pointsController = TextEditingController(text: widget.user.points.toString());
    isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    cityController.dispose();
    addressController.dispose();
    nearController.dispose();
    pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: Get.width * 0.9,
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // العنوان
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'تعديل معلومات المستخدم',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // النموذج
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // الاسم
                    _buildTextField(
                      controller: nameController,
                      label: 'الاسم الكامل',
                      icon: Icons.person,
                    ),
                    SizedBox(height: 15),
                    
                    // رقم الهاتف
                    _buildTextField(
                      controller: phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 15),
                    
                    // المدينة
                    _buildTextField(
                      controller: cityController,
                      label: 'المدينة',
                      icon: Icons.location_city,
                    ),
                    SizedBox(height: 15),
                    
                    // العنوان
                    _buildTextField(
                      controller: addressController,
                      label: 'العنوان',
                      icon: Icons.home,
                      maxLines: 2,
                    ),
                    SizedBox(height: 15),
                    
                    // المنطقة القريبة
                    _buildTextField(
                      controller: nearController,
                      label: 'المنطقة القريبة',
                      icon: Icons.location_on,
                    ),
                    SizedBox(height: 15),
                    
                    // النقاط
                    _buildTextField(
                      controller: pointsController,
                      label: 'النقاط',
                      icon: Icons.stars,
                      keyboardType: TextInputType.number,
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
                            'حالة الحساب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          Switch(
                            value: isActive,
                            onChanged: (value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                          ),
                          Text(
                            isActive ? 'نشط' : 'محظور',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // زر عرض الموقع (إذا كان متوفراً)
                    if (widget.user.shopLocation != null) ...[
                      SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openLocationOnMaps(),
                          icon: Icon(Icons.location_on),
                          label: Text('عرض موقع المحل على خرائط جوجل'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // الأزرار
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'حفظ التعديلات',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.deepPurple),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  void _saveUser() {
    // التحقق من صحة البيانات
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال الاسم');
      return;
    }
    
    if (phoneController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال رقم الهاتف');
      return;
    }

    // التحقق من صحة النقاط
    int? points;
    try {
      points = int.parse(pointsController.text.trim());
    } catch (e) {
      Get.snackbar('خطأ', 'يرجى إدخال عدد صحيح للنقاط');
      return;
    }

    // إنشاء المستخدم المحدث
    final updatedUser = widget.user.copyWith(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      city: cityController.text.trim(),
      address: addressController.text.trim(),
      near: nearController.text.trim(),
      points: points,
      isActive: isActive,
      updatedAt: DateTime.now(),
    );

    // حفظ التعديلات
    widget.onSave(updatedUser);
    Get.back();
  }

  // فتح الموقع على خرائط جوجل
  Future<void> _openLocationOnMaps() async {
    if (widget.user.shopLocation == null) return;
    
    final lat = widget.user.shopLocation!['lat'];
    final lng = widget.user.shopLocation!['lng'];
    
    if (lat == null || lng == null) return;
    
    // إنشاء رابط خرائط جوجل
    final googleMapsUrl = 'https://www.google.com/maps?q=$lat,$lng';
    final appleMapsUrl = 'https://maps.apple.com/?q=$lat,$lng';
    
    try {
      // محاولة فتح خرائط جوجل أولاً
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
        // إذا فشل، جرب خرائط آبل
        await launchUrl(
          Uri.parse(appleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // إذا فشل كلاهما، اعرض رسالة خطأ
        throw Exception('لا يمكن فتح خرائط جوجل');
      }
    } catch (e) {
      // عرض رسالة خطأ للمستخدم
      Get.snackbar(
        'خطأ',
        'لا يمكن فتح خرائط جوجل: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
