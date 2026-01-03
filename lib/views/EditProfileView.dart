import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'MapPicker.dart';
import 'package:ecommerce/main.dart';

class EditProfileView extends StatefulWidget {
  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController shopNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  File? profileImage;
  LatLng? shopLocation;
  bool isUploading = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage(File file, String userId, String type) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('userspic/$userId-$type.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  Future<void> saveProfile() async {
    if (isUploading) return;
    
    setState(() {
      isUploading = true;
    });

    try {
      final phone = sharedPreferences?.getString('phone');
      if (phone == null) {
        Get.snackbar('خطأ', 'لم يتم العثور على رقم الهاتف');
        return;
      }

      String? profileUrl;
      if (profileImage != null) {
        profileUrl = await uploadImage(profileImage!, phone, 'profile');
        if (profileUrl == null) {
          Get.snackbar('خطأ', 'فشل في رفع الصورة الشخصية');
          return;
        }
      }

      // البحث عن المستخدم بالهاتف
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      
      if (userDoc.docs.isEmpty) {
        Get.snackbar('خطأ', 'لم يتم العثور على المستخدم في قاعدة البيانات');
        return;
      }

      final docId = userDoc.docs.first.id;
      final now = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'name': shopNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'updatedAt': now,
        if (profileUrl != null) 'profilePic': profileUrl,
        if (shopLocation != null) 'shopLocation': {
          'lat': shopLocation!.latitude, 
          'lng': shopLocation!.longitude
        },
      });
      
      // تحديث البيانات في SharedPreferences أيضاً
      await sharedPreferences?.setString('name', shopNameController.text.trim());
      await sharedPreferences?.setString('phone', phoneController.text.trim());
      await sharedPreferences?.setString('near', addressController.text.trim());
      if (profileUrl != null) {
        await sharedPreferences?.setString('profilePic', profileUrl);
      }
      
      Get.back();
      Get.snackbar('تم الحفظ', 'تم تحديث معلومات المحل بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء حفظ البيانات: $e');
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // جلب البيانات القديمة من sharedPreferences
    shopNameController.text = sharedPreferences?.getString('name') ?? '';
    phoneController.text = sharedPreferences?.getString('phone') ?? '';
    addressController.text = sharedPreferences?.getString('near') ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'تعديل معلومات المحل',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // صورة المحل
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'صورة المحل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: profileImage != null
                            ? ClipOval(
                                child: Image.file(
                                  profileImage!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                ),
                              )
                            : Icon(
                                Icons.store,
                                size: 50,
                                color: Colors.deepPurple,
                              ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'اضغط لتغيير الصورة',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // الحقول
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // اسم المحل
                    _buildFormField(
                      controller: shopNameController,
                      label: 'اسم المحل',
                      icon: Icons.store,
                      validator: (v) => v == null || v.isEmpty ? 'اسم المحل مطلوب' : null,
                    ),
                    
                    SizedBox(height: 20),
                    
                    // رقم الهاتف
                    _buildFormField(
                      controller: phoneController,
                      label: 'رقم الهاتف',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'رقم الهاتف مطلوب' : null,
                    ),
                    
                    SizedBox(height: 20),
                    
                    // العنوان
                    _buildFormField(
                      controller: addressController,
                      label: 'عنوان المحل',
                      icon: Icons.location_on,
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'عنوان المحل مطلوب' : null,
                    ),
                    
                    SizedBox(height: 30),
                    
                    // تحديد الموقع
                    _buildLocationSection(),
                    
                    SizedBox(height: 30),
                    
                    // زر الحفظ
                    _buildSaveButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                'موقع المحل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.my_location, color: Colors.white),
                  label: Text('الموقع الحالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      Position pos = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                      );
                      setState(() {
                        shopLocation = LatLng(pos.latitude, pos.longitude);
                      });
                      Get.snackbar('تم التحديد', 'تم تحديد الموقع بنجاح');
                    } catch (e) {
                      Get.snackbar('خطأ', 'فشل في تحديد الموقع الحالي');
                    }
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.map, color: Colors.white),
                  label: Text('من الخريطة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    LatLng? result = await Get.to(() => MapPicker(initialLocation: shopLocation));
                    if (result != null) {
                      setState(() {
                        shopLocation = result;
                      });
                      Get.snackbar('تم التحديد', 'تم تحديد الموقع بنجاح');
                    }
                  },
                ),
              ),
            ],
          ),
          if (shopLocation != null) ...[
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم تحديد الموقع بنجاح',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isUploading ? null : () async {
          if (_formKey.currentState!.validate()) {
            await saveProfile();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
        ),
        child: isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'جاري الحفظ...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'حفظ التعديلات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
