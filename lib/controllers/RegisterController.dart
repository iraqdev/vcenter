import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ecommerce/services/dnz_push_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../Bindings/Landing_bindings.dart';
import '../Services/RemoteServices.dart';
import '../Services/whatsapp_otp_service.dart';
import '../main.dart';
import '../utils/price_utils.dart';
import '../views/Landing.dart';
import '../views/MapPicker.dart';
import '../views/OtpVerifyView.dart';

class RegisterController extends GetxController {
  late bool loading = false;
  late bool errorRegister = false;
  late String errormsg = '';
  late TextEditingController phone_ = TextEditingController();
  late TextEditingController password_ = TextEditingController();
  late TextEditingController name_ = TextEditingController();
  late TextEditingController address_ = TextEditingController();
  late TextEditingController pageName_ = TextEditingController();
  late TextEditingController customerName_ = TextEditingController();
  late TextEditingController customerPhone_ = TextEditingController();
  late TextEditingController customerLandmark_ = TextEditingController();
  late TextEditingController customerPassword_ = TextEditingController();
  int selectedRegisterTab = 0;
  File? shopImageFile;

  Position? _currentPosition;
  // المواقع المتاحة فقط - إحداثيات دقيقة للفروع
  LatLng _adhamya = LatLng(33.36961, 44.36373); // الاعظمية
  LatLng _algazaly = LatLng(33.344803, 44.280755); // الغزالية
  LatLng _zafrania = LatLng(33.26082, 44.49870); // الزعفرانية

  String closestPoint = 'لم يتم تحديد الموقع';
  String closestBranchName = '';
  bool isLocationLoading = true;
  bool locationPermissionGranted = false;
  LatLng? shopLocation;
  bool showLocationChoice = false;

  List<String> governorates_en = [
    'Baghdad',
    'Basra',
    'Dhi Qar',
    'Wasit',
    'Maysan',
    'Muthanna',
    'Karbala',
    'Najaf',
    'Qadisiyah',
    'Babil',
    'Diyala',
    'Salah ad-Din',
    'Kirkuk',
    'Nineveh',
    'Erbil',
    'Dohuk',
    'Sulaymaniyah',
    'Al-Anbar',
  ];

  List<String> governorates_ar = [
    'بغداد',
    'البصرة',
    'ذي قار',
    'واسط',
    'ميسان',
    'المثنى',
    'كربلاء',
    'النجف',
    'القادسية',
    'بابل',
    'ديالى',
    'صلاح الدين',
    'كركوك',
    'نينوى',
    'اربيل',
    'دهوك',
    'السليمانية',
    'الانبار',
  ];

  double _calculateDistance(LatLng point) {
    if (_currentPosition != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        point.latitude,
        point.longitude,
      );
      print("${_currentPosition!.latitude} ${_currentPosition!.longitude}");
      return distanceInMeters;
    }
    return double.infinity; // Return infinity if position is null
  }

  // دالة محدثة لطلب الصلاحيات - تستخدم permission_handler فقط
  Future<void> requestLocationPermission() async {
    // استدعاء الطريقة البديلة مباشرة
    await requestLocationPermissionAlternative();
  }

  // تم حذف الطريقة القديمة لتجنب مشاكل geolocator

  // دالة لحساب المسافة بين نقطتين باستخدام صيغة Haversine
  double _calculateDistanceBetweenPoints(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // نصف قطر الأرض بالمتر
    
    double lat1Rad = point1.latitude * (3.14159265359 / 180);
    double lat2Rad = point2.latitude * (3.14159265359 / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * asin(sqrt(a));

    return earthRadius * c; // المسافة بالمتر
  }

  // دالة لتحديد أقرب فرع للموقع المختار
  String _findClosestBranch(LatLng userLocation) {
    // التحقق من المحافظة المختارة أولاً
    if (selectedGovernorate == null || selectedGovernorate != 'بغداد') {
      print('🏛️ المحافظة: $selectedGovernorate - سيتم حفظ "العراق"');
      return 'العراق';
    }
    
    print('🏛️ المحافظة: $selectedGovernorate - سيتم حساب أقرب فرع في بغداد');
    
    Map<String, LatLng> branches = {
      'الاعظمية': _adhamya,
      'الغزالية': _algazaly,
      'الزعفرانية': _zafrania,
    };

    String closestBranch = '';
    double minDistance = double.infinity;

    branches.forEach((branchName, branchLocation) {
      double distance = _calculateDistanceBetweenPoints(userLocation, branchLocation);
      print('المسافة إلى $branchName: ${(distance / 1000).toStringAsFixed(2)} كم');
      
      if (distance < minDistance) {
        minDistance = distance;
        closestBranch = branchName;
      }
    });

    print('أقرب فرع: $closestBranch - المسافة: ${(minDistance / 1000).toStringAsFixed(2)} كم');
    return closestBranch;
  }

  // Function to request location permission and get current location

  void _findClosestPoint() {
    try {
      if (_currentPosition == null) {
        closestPoint = 'لم يتم تحديد الموقع';
        isLocationLoading = false;
        update();
        return;
      }

      double minDistance = double.infinity;
      String closest = '';
      final Map<String, LatLng> points = {
        'الاعظمية': _adhamya,
        'الغزالية': _algazaly,
        'الزعفرانية': _zafrania,
      };

      points.forEach((key, value) {
        double distance = _calculateDistance(value);
        if (distance < minDistance) {
          minDistance = distance;
          closest = key;
        }
      });

      if (closest.isNotEmpty) {
        closestPoint = closest;
        print(
          "أقرب فرع: $closest - المسافة: ${(minDistance / 1000).toStringAsFixed(2)} كم",
        );
      } else {
        closestPoint = 'لم يتم العثور على فرع قريب';
      }

      isLocationLoading = false;
      update();
    } catch (e) {
      print("خطأ في حساب أقرب فرع: $e");
      closestPoint = 'خطأ في حساب المسافة';
      isLocationLoading = false;
      update();
    }
  }

  void is_loading() {
    loading = true;
    update();
  }

  List<String> gonvernorates = [];
  String? selectedGovernorate;
  List<String> shopAreas = [
    'زيونة',
    'شارع فلسطين',
    'كرادة',
    'الأمين',
    'المشتل',
    'بلديات',
    'الزعفرانية',
    'اعضمية',
    'كريعات',
    'حي القاهرة',
    'البنوك',
    'الكاظمية',
    'حي تونس',
    'باب المعظم',
    'الكفاح',
    'الغزالية',
    'العامرية',
    'حي الخضراء',
    'الشعلة',
    'حي الجهاد',
    'البياع',
    'حي الشهداء',
  ];
  String? selectedShopArea;
  String? customerSelectedGovernorate;
  void changeCustomerGovernorate(String? value) {
    customerSelectedGovernorate = value;
    update();
  }

  String get _customerAreaValue {
    return customerSelectedGovernorate?.trim() ?? '';
  }

  void changeSelect(value) {
    final prev = selectedGovernorate;
    selectedGovernorate = value;
    selectedShopArea = null;
    if (value == 'بغداد') {
      if (prev != 'بغداد') {
        address_.clear();
      }
    } else {
      address_.text = value ?? '';
    }
    update();
  }

  void changeShopArea(String? value) {
    selectedShopArea = value;
    address_.text = value ?? '';
    update();
  }

  void isnot_loading() {
    loading = false;
    update();
  }

  void is_error() {
    errorRegister = true;
    update();
  }

  void clearError() {
    errorRegister = false;
    errormsg = '';
    update();
  }

  Future<void> pickShopImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      shopImageFile = File(picked.path);
      update();
    }
  }

  Future<String?> _uploadShopImage(String phone) async {
    if (shopImageFile == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('userspic/$phone-shop.jpg');
      await ref.putFile(shopImageFile!);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void changeRegisterTab(int index) {
    selectedRegisterTab = index;
    showLocationChoice = false;
    clearError();
    update();
  }

  // دالة لحفظ FCM token في Firebase
  Future<void> _saveFcmTokenToFirebase(String phone) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      
      if (fcmToken != null && fcmToken.isNotEmpty) {
        // البحث عن المستخدم في Firebase باستخدام رقم الهاتف
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phone)
            .get();
        
        if (usersSnapshot.docs.isNotEmpty) {
          // تحديث المستخدم بإضافة fcmToken
          await FirebaseFirestore.instance
              .collection('users')
              .doc(usersSnapshot.docs.first.id)
              .update({
            'fcmToken': fcmToken,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          print('تم حفظ FCM token للمستخدم الجديد: $phone');
          await DnzPushService.registerCustomer(phone);
        }
      }
    } catch (e) {
      print('خطأ في حفظ FCM token: $e');
    }
  }

  Future<void> register() async {
    clearError();
    // التحقق من الحقول
    if (name_.text.isEmpty) {
      errormsg = "يرجى إدخال الاسم الكامل.";
      is_error();
      return;
    } else if (phone_.text.isEmpty) {
      errormsg = "يرجى إدخال رقم الهاتف.";
      is_error();
      return;
    } else if (password_.text.isEmpty) {
      errormsg = "يرجى إدخال كلمة المرور.";
      is_error();
      return;
    } else if (selectedGovernorate == null || selectedGovernorate!.isEmpty) {
      errormsg = "يرجى اختيار المحافظة.";
      is_error();
      return;
    } else if (address_.text.isEmpty) {
      errormsg = "يرجى إدخال العنوان.";
      is_error();
      return;
    }

    // التحقق من صحة البيانات
    if (name_.text.length < 3) {
      errormsg = "الاسم قصير جداً. يجب أن يكون 3 أحرف على الأقل.";
      is_error();
      return;
    }

    if (phone_.text.length != 11) {
      errormsg =
          "رقم الهاتف غير صحيح. يجب أن يكون 11 رقم (رقم هاتف عراقي صحيح).";
      is_error();
      return;
    }

    // التحقق من أن رقم الهاتف يبدأ بـ 07
    if (!phone_.text.startsWith('07')) {
      errormsg =
          "رقم الهاتف غير صحيح. يجب أن يبدأ بـ 07 (رقم هاتف عراقي صحيح).";
      is_error();
      return;
    }

    if (password_.text.length < 6) {
      errormsg = "كلمة المرور قصيرة جداً. يجب أن تكون 6 أحرف على الأقل.";
      is_error();
      return;
    }

    if (address_.text.trim().isEmpty) {
      errormsg = "اسم المنطقة مطلوب.";
      is_error();
      return;
    }

    if (shopImageFile == null) {
      errormsg = "يرجى إضافة صورة المحل.";
      is_error();
      return;
    }

    // التحقق من وجود موقع المحل
    if (shopLocation == null) {
      errormsg = "يجب تحديد موقع المحل لإنشاء الحساب.";
      is_error();
      return;
    }

    await _requestOtpAndOpenVerify(
      phone: phone_.text.trim(),
      onVerified: (_) => _completeShopRegistration(),
    );
  }

  Future<void> _requestOtpAndOpenVerify({
    required String phone,
    required Future<void> Function(String code) onVerified,
  }) async {
    is_loading();
    final result = await WhatsAppOtpService.requestOtp(
      phone: phone,
      purpose: 'register',
    );
    isnot_loading();

    if (result['ok'] != true) {
      errormsg = result['message']?.toString() ??
          'فشل إرسال رمز التحقق عبر واتساب.';
      is_error();
      return;
    }

    Get.to(
      () => OtpVerifyView(
        phone: phone,
        purpose: 'register',
        onVerified: (code) async {
          await onVerified(code);
        },
      ),
    );
  }

  Future<void> _completeShopRegistration() async {
    clearError();
    is_loading();
    final shopPicUrl = await _uploadShopImage(phone_.text.trim());
    if (shopPicUrl == null || shopPicUrl.isEmpty) {
      errormsg = "فشل رفع صورة المحل. حاول مرة أخرى.";
      is_error();
      isnot_loading();
      return;
    }
    var response = await RemoteServices.register(
      phone_.text.trim(),
      name_.text.trim(),
      password_.text.trim(),
      selectedGovernorate!,
      address_.text.trim(),
      closestPoint,
      shopLocation,
      closestBranchName,
      shopPicUrl: shopPicUrl,
    );

    if (response != null) {
      var json_response = jsonDecode(response);
      print(json_response);
      if (json_response['message'] == "Register Successfully") {
        Future.delayed(Duration(seconds: 2), () {
          _saveFcmTokenToFirebase(phone_.text.trim());
        });

        isnot_loading();
        shopImageFile = null;
        update();
        Get.offAllNamed('/');
        Get.snackbar(
          'تم',
          'تم إنشاء الحساب. بانتظار الموافقة.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
        );
      } else if (json_response['message'] == "Phone number already in use") {
        errormsg =
            "رقم الهاتف مستخدم بالفعل. يرجى استخدام رقم هاتف آخر أو تسجيل الدخول إذا كان لديك حساب.";
        is_error();
        print(json_response['message']);
        isnot_loading();
        Get.back();
      } else if (json_response['message'] == "Invalid phone number") {
        errormsg =
            "رقم الهاتف غير صحيح. تأكد من إدخال رقم هاتف عراقي صحيح (11 رقم يبدأ بـ 07).";
        is_error();
        print(json_response['message']);
        isnot_loading();
        Get.back();
      } else if (json_response['message'] == "Password too short") {
        errormsg = "كلمة المرور قصيرة جداً. يجب أن تكون 6 أحرف على الأقل.";
        is_error();
        print(json_response['message']);
        isnot_loading();
        Get.back();
      } else if (json_response['message'] == "Invalid name") {
        errormsg = "الاسم غير صحيح. يرجى إدخال اسم صحيح.";
        is_error();
        print(json_response['message']);
        isnot_loading();
        Get.back();
      } else if (json_response['message'] == "Missing required fields") {
        errormsg = "يرجى ملء جميع الحقول المطلوبة.";
        is_error();
        print(json_response['message']);
        isnot_loading();
        Get.back();
      } else {
        errormsg = "حدث خطأ أثناء إنشاء الحساب. يرجى المحاولة مرة أخرى.";
        is_error();
        print(json_response['message']);
        isnot_loading();
        Get.back();
      }
    } else {
      errormsg =
          "فشل الاتصال بالخادم. تحقق من اتصال الإنترنت وحاول مرة أخرى.";
      is_error();
      isnot_loading();
      Get.back();
    }
  }

  Future<void> _persistSessionAndOpenApp(Map<String, dynamic> json) async {
    await sharedPreferences!.setString('phone', json['phone']);
    await sharedPreferences!.setInt('user_id', json['user_id']);
    await sharedPreferences!.setString('near', json['near'] ?? '');
    await sharedPreferences!.setString('nearpoint', json['nearpoint'] ?? '');
    await sharedPreferences!.setString('city', json['city'] ?? '');
    await sharedPreferences!.setString('address', json['address'] ?? '');
    await sharedPreferences!.setInt('active', json['active']);
    await sharedPreferences!.setString('name', json['username']);
    await sharedPreferences!.setString(
      'userType',
      json['userType']?.toString() ?? kCustomerUserType,
    );
    Future.delayed(const Duration(seconds: 2), () {
      _saveFcmTokenToFirebase(json['phone']);
    });
    isnot_loading();
    Get.off(() => Landing(), binding: Landing_bindings());
  }

  Future<void> submitCustomerRequest() async {
    clearError();

    if (customerName_.text.trim().isEmpty) {
      errormsg = "يرجى إدخال الاسم.";
      is_error();
      return;
    }
    if (customerPhone_.text.trim().isEmpty) {
      errormsg = "يرجى إدخال رقم الهاتف.";
      is_error();
      return;
    }
    if (customerPassword_.text.trim().isEmpty) {
      errormsg = "يرجى إدخال كلمة المرور.";
      is_error();
      return;
    }
    if (customerSelectedGovernorate == null ||
        customerSelectedGovernorate!.trim().isEmpty) {
      errormsg = "يرجى اختيار المحافظة.";
      is_error();
      return;
    }
    final area = _customerAreaValue;
    if (area.isEmpty) {
      errormsg = "يرجى اختيار المحافظة.";
      is_error();
      return;
    }
    if (customerLandmark_.text.trim().isEmpty) {
      errormsg = "يرجى إدخال أقرب نقطة دالة.";
      is_error();
      return;
    }

    if (customerPhone_.text.trim().length != 11 ||
        !customerPhone_.text.trim().startsWith('07')) {
      errormsg = "رقم الهاتف غير صحيح. يجب أن يكون 11 رقم ويبدأ بـ 07.";
      is_error();
      return;
    }

    if (customerPassword_.text.trim().length < 6) {
      errormsg = "كلمة المرور قصيرة. يجب أن تكون 6 أحرف على الأقل.";
      is_error();
      return;
    }

    await _requestOtpAndOpenVerify(
      phone: customerPhone_.text.trim(),
      onVerified: (_) => _completeCustomerRegistration(),
    );
  }

  Future<void> _completeCustomerRegistration() async {
    clearError();
    final phone = customerPhone_.text.trim();
    final password = customerPassword_.text.trim();
    final area = _customerAreaValue;

    is_loading();
    final response = await RemoteServices.registerCustomer(
      name: customerName_.text.trim(),
      phone: phone,
      password: password,
      governorate: customerSelectedGovernorate!.trim(),
      area: area,
      nearpoint: customerLandmark_.text.trim(),
    );

    if (response == null) {
      errormsg = "فشل الاتصال. تحقق من الإنترنت وحاول مرة أخرى.";
      is_error();
      isnot_loading();
      Get.back();
      return;
    }

    final jsonResponse = jsonDecode(response);
    if (jsonResponse['message'] == "Register Successfully") {
      final loginResponse = await RemoteServices.login(phone, password);
      if (loginResponse != null) {
        final loginJson = jsonDecode(loginResponse);
        if (loginJson['message'] == "Login Successfully") {
          customerName_.clear();
          customerPhone_.clear();
          customerPassword_.clear();
          customerSelectedGovernorate = null;
          customerLandmark_.clear();
          await _persistSessionAndOpenApp(
            Map<String, dynamic>.from(loginJson),
          );
          return;
        }
      }
      errormsg = "تم إنشاء الحساب لكن فشل تسجيل الدخول. جرّب تسجيل الدخول يدوياً.";
      is_error();
      isnot_loading();
      Get.offAllNamed('/');
    } else if (jsonResponse['message'] == "Phone number already in use") {
      errormsg =
          "رقم الهاتف مستخدم. سجّل الدخول إن كان لديك حساب، أو استخدم رقماً آخر.";
      is_error();
      isnot_loading();
      Get.back();
    } else {
      errormsg = "حدث خطأ أثناء إنشاء الحساب. حاول مرة أخرى.";
      is_error();
      isnot_loading();
      Get.back();
    }
  }

  void showLocationChoiceDialog() {
    showLocationChoice = true;
    update();
  }

  void hideLocationChoice() {
    showLocationChoice = false;
    update();
  }

  // دالة فتح الخريطة مع الموقع الحالي
  Future<void> openLocationMap() async {
    try {
      // التحقق من تفعيل خدمات الموقع (مهم لـ iOS)
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('خطأ', 'يرجى تفعيل خدمات الموقع من إعدادات الجهاز');
        return;
      }

      // طلب صلاحيات الموقع أولاً
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        Get.snackbar('خطأ', 'يجب منح صلاحية الموقع لإنشاء الحساب');
        return;
      }
      
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('خطأ', 'تم رفض صلاحية الموقع نهائياً. يرجى تفعيلها من الإعدادات');
        return;
      }
      
      // محاولة الحصول على الموقع الحالي (مع timeout أطول لـ iOS)
      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        );
      } catch (e) {
        print('فشل في الحصول على الموقع الحالي: $e');
        // على iOS: فتح الخريطة بموقع افتراضي (بغداد) إذا فشل الحصول على الموقع
        currentPosition = null;
      }

      LatLng initialLoc;
      if (currentPosition != null) {
        initialLoc = LatLng(currentPosition!.latitude, currentPosition!.longitude);
      } else {
        initialLoc = LatLng(33.3152, 44.3661);
      }
      
      // فتح الخريطة مع الموقع الحالي أو الافتراضي
      LatLng? result = await Get.to(() => MapPicker(initialLocation: initialLoc));
      
      if (result != null) {
        shopLocation = result;
        
        // حساب أقرب فرع للموقع المختار
        closestBranchName = _findClosestBranch(result);
        closestPoint = 'أقرب فرع: $closestBranchName';
        
        hideLocationChoice();
        Get.snackbar('تم التحديد', 'تم اختيار موقع المحل من الخريطة\n$closestPoint');
        
        // إنشاء الحساب مباشرة بعد تحديد الموقع
        await register();
      } else {
        Get.snackbar('خطأ', 'لم يتم تحديد موقع. يجب تحديد موقع لإنشاء الحساب');
      }
    } catch (e, stack) {
      print('خطأ في openLocationMap: $e\n$stack');
      Get.snackbar('خطأ', 'فشل في فتح الخريطة. يرجى المحاولة مرة أخرى');
    }
  }

  Future<void> useCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      shopLocation = LatLng(pos.latitude, pos.longitude);
      hideLocationChoice();
      Get.snackbar('تم التحديد', 'تم تحديد الموقع بنجاح');
      // إنشاء الحساب مباشرة بعد تحديد الموقع
      await register();
    } catch (e) {
      Get.snackbar('خطأ', 'فشل في تحديد الموقع الحالي');
    }
  }

  Future<void> chooseLocationFromMap() async {
    LatLng? result = await Get.to(() => MapPicker(initialLocation: shopLocation));
    if (result != null) {
      shopLocation = result;
      hideLocationChoice();
        Get.snackbar('تم التحديد', 'تم تحديد الموقع بنجاح');
      // إنشاء الحساب مباشرة بعد تحديد الموقع
      await register();
    }
  }

  void skipLocationSelection() {
    Get.snackbar('مطلوب', 'يجب تحديد موقع المحل لإنشاء الحساب');
  }

  // دالة بديلة لطلب الصلاحيات باستخدام permission_handler
  Future<void> requestLocationPermissionAlternative() async {
    try {
      isLocationLoading = true;
      update();

      print("بدء طلب صلاحيات الموقع باستخدام permission_handler...");

      // التحقق من تفعيل خدمات الموقع أولاً
      bool serviceEnabled;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        print("حالة خدمات الموقع: ${serviceEnabled ? 'مفعلة' : 'معطلة'}");
      } catch (e) {
        print("خطأ في فحص خدمات الموقع: $e");
        closestPoint = 'خطأ في فحص خدمات الموقع';
        isLocationLoading = false;
        locationPermissionGranted = false;
        update();
        return;
      }

      if (!serviceEnabled) {
        print("خدمات الموقع غير مفعلة - سيتم عرض حوار التفعيل");
        closestPoint = 'يرجى تفعيل خدمات الموقع';
        isLocationLoading = false;
        locationPermissionGranted = false;
        update();

        // تأخير عرض الحوار قليلاً للسماح للواجهة بالتحديث
        Future.delayed(Duration(milliseconds: 500), () {
          showLocationServiceDialog();
        });
        return;
      }

      // استخدام permission_handler للتحقق من الصلاحيات
      PermissionStatus locationStatus;
      try {
        locationStatus = await Permission.location.status;
        print("حالة الصلاحية الحالية (permission_handler): $locationStatus");
      } catch (e) {
        print("خطأ في فحص صلاحيات الموقع باستخدام permission_handler: $e");
        closestPoint = 'خطأ في فحص صلاحيات الموقع';
        isLocationLoading = false;
        locationPermissionGranted = false;
        update();
        return;
      }

      if (locationStatus.isDenied) {
        print("الصلاحية مرفوضة - سيتم عرض الحوار التوضيحي");
        // عرض رسالة توضيحية قبل طلب الصلاحية
        bool shouldRequest = await _showPermissionExplanationDialog();

        if (shouldRequest) {
          print("المستخدم وافق - سيتم طلب الصلاحية");
          locationStatus = await Permission.location.request();
          print("حالة الصلاحية بعد الطلب: $locationStatus");

          if (locationStatus.isDenied) {
            print("تم رفض الصلاحية من المستخدم");
            closestPoint = 'تم رفض صلاحية الموقع';
            isLocationLoading = false;
            locationPermissionGranted = false;
            update();
            _showPermissionDeniedDialog();
            return;
          }
        } else {
          print("المستخدم رفض طلب الصلاحية");
          closestPoint = 'لم يتم طلب صلاحية الموقع';
          isLocationLoading = false;
          locationPermissionGranted = false;
          update();
          return;
        }
      }

      if (locationStatus.isPermanentlyDenied) {
        print("الصلاحية مرفوضة نهائياً");
        closestPoint = 'صلاحية الموقع مرفوضة نهائياً';
        isLocationLoading = false;
        locationPermissionGranted = false;
        update();
        _showPermissionDeniedForeverDialog();
        return;
      }

      // التحقق من أن الصلاحية مُمنوحة
      if (!locationStatus.isGranted) {
        print("الصلاحية غير كافية: $locationStatus");
        closestPoint = 'صلاحية الموقع غير كافية';
        isLocationLoading = false;
        locationPermissionGranted = false;
        update();
        return;
      }

      print("الصلاحية مُمنوحة: $locationStatus");

      // الحصول على الموقع الحالي
      print("محاولة الحصول على الموقع...");
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        );
      } catch (e) {
        print("خطأ في الحصول على الموقع الحالي: $e");
        // جرب الحصول على آخر موقع معروف
        try {
          Position? lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            position = lastPosition;
            print(
              "تم استخدام آخر موقع معروف: ${position.latitude}, ${position.longitude}",
            );
          } else {
            throw Exception("لا يوجد موقع معروف سابقاً");
          }
        } catch (e2) {
          print("فشل في الحصول على آخر موقع معروف: $e2");
          closestPoint = 'فشل في تحديد الموقع';
          isLocationLoading = false;
          locationPermissionGranted = false;
          update();
          return;
        }
      }

      print(
        "تم الحصول على الموقع: ${position.latitude}, ${position.longitude}",
      );
      _currentPosition = position;
      locationPermissionGranted = true;
      _findClosestPoint();
    } catch (e) {
      print("خطأ في طلب صلاحيات الموقع: $e");
      closestPoint = 'خطأ في الحصول على الموقع';
      isLocationLoading = false;
      locationPermissionGranted = false;
      update();
    }
  }

  // إضافة دالة لإعادة المحاولة
  void retryLocationPermission() {
    // جرب الطريقة البديلة أولاً
    requestLocationPermissionAlternative();
  }

  // عرض رسالة توضيحية قبل طلب صلاحية الموقع
  Future<bool> _showPermissionExplanationDialog() async {
    return await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on, color: Colors.blue, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'صلاحية الوصول للموقع',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نحتاج للوصول إلى موقعك لتحديد أقرب فرع لك وتوفير خدمة أفضل.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'فوائد السماح بالوصول:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• تحديد أقرب فرع تلقائياً\n• توفير الوقت والجهد\n• خدمة توصيل أسرع\n• عروض خاصة بمنطقتك',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'نحن نحترم خصوصيتك ولا نحفظ بياناتك الشخصية',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back(result: false); // إغلاق الدايلوج
                },
                child: Text(
                  'لا، شكراً',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back(result: true); // إغلاق الدايلوج
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'السماح بالوصول',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }

  // عرض رسالة عند رفض الصلاحية
  void _showPermissionDeniedDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off, color: Colors.orange, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'تم رفض الصلاحية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لم يتم السماح بالوصول للموقع. يمكنك المتابعة بدون تحديد الموقع أو إعادة المحاولة.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكنك تفعيل الصلاحية لاحقاً من إعدادات التطبيق',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // إغلاق الدايلوج
            },
            child: Text(
              'المتابعة بدون موقع',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // إغلاق الدايلوج أولاً
              // تنفيذ إعادة المحاولة بعد إغلاق الدايلوج
              Future.delayed(Duration(milliseconds: 100), () {
                retryLocationPermission();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'إعادة المحاولة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  // عرض رسالة عند الرفض النهائي للصلاحية
  void _showPermissionDeniedForeverDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.block, color: Colors.red, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'صلاحية محظورة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم رفض صلاحية الموقع نهائياً. لتفعيلها، يجب الذهاب لإعدادات التطبيق.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خطوات التفعيل:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. اذهب لإعدادات الجهاز\n2. ابحث عن "التطبيقات" أو "Apps"\n3. اختر تطبيق VCenter\n4. اذهب للصلاحيات\n5. فعّل صلاحية الموقع',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // إغلاق الدايلوج
            },
            child: Text(
              'المتابعة بدون موقع',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // إغلاق الدايلوج أولاً
              // فتح إعدادات التطبيق بعد إغلاق الدايلوج
              Future.delayed(Duration(milliseconds: 100), () {
                Geolocator.openAppSettings();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'فتح الإعدادات',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  // عرض رسالة لتفعيل خدمات الموقع
  void showLocationServiceDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_off, color: Colors.orange, size: 24),
            ),
            SizedBox(width: 12),
            Text(
              'خدمات الموقع معطلة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لتحديد أقرب فرع لك، يرجى تفعيل خدمات الموقع من إعدادات الجهاز.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'خطوات التفعيل:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. اذهب إلى إعدادات الجهاز\n2. ابحث عن "الموقع" أو "Location"\n3. قم بتفعيل خدمات الموقع\n4. ارجع للتطبيق واضغط "إعادة المحاولة"',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكنك المتابعة بدون تحديد الموقع',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // إغلاق الدايلوج
            },
            child: Text(
              'المتابعة بدون موقع',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back(); // إغلاق الدايلوج أولاً
              // فتح إعدادات الموقع بعد إغلاق الدايلوج
              Future.delayed(Duration(milliseconds: 100), () {
                Geolocator.openLocationSettings();
                // إعادة المحاولة بعد فترة قصيرة
                Future.delayed(Duration(seconds: 2), () {
                  retryLocationPermission();
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'فتح الإعدادات',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  @override
  void onInit() {
    print("RegisterController onInit() تم استدعاؤها");
    gonvernorates = governorates_ar;
    super.onInit();
  }
}
