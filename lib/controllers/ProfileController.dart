import 'package:get/get.dart';
import 'package:ecommerce/models/UserInfo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/RemoteServices.dart';
import '../main.dart';
import '../views/Login.dart';
import '../utils/whatsapp_helper.dart';

class ProfileController extends GetxController {
  final isLoadingUser = true.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final userList = <UserInfo>[].obs;
  final isLoggedIn = false.obs;
  final profilePicUrl = ''.obs;

  void checkLoginStatus() {
    var phone = sharedPreferences?.getString('phone');
    isLoggedIn.value = phone != null && phone.isNotEmpty;
  }

  void fetchProfile() async {
    userList.clear();
    var phone = sharedPreferences?.getString('phone');

    if (phone == null || phone.isEmpty) {
      hasError.value = true;
      errorMessage.value = 'Phone number not found';
      isLoadingUser.value = false;
      update();
      return;
    }

    isLoadingUser.value = true;
    hasError.value = false;

    try {
      // استخدام البيانات من SharedPreferences مباشرة
      var name = sharedPreferences?.getString('name') ?? '';
      var near = sharedPreferences?.getString('near') ?? '';
      
      // جلب الصورة الشخصية من SharedPreferences أولاً، ثم من Firebase
      String profilePic = sharedPreferences?.getString('profilePic') ?? '';
      
      // إذا لم تكن الصورة محفوظة محلياً، جلبها من Firebase
      if (profilePic.isEmpty) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();
          
          if (userDoc.docs.isNotEmpty) {
            var userData = userDoc.docs.first.data();
            profilePic = userData['profilePic'] ?? '';
            // حفظ الصورة في SharedPreferences للاستخدام المستقبلي
            if (profilePic.isNotEmpty) {
              await sharedPreferences?.setString('profilePic', profilePic);
            }
          }
        } catch (e) {
          print('خطأ في جلب الصورة الشخصية: $e');
          // لا نوقف العملية إذا فشل جلب الصورة
        }
      }
      
      if (name.isNotEmpty && phone.isNotEmpty) {
        // إنشاء UserInfo من البيانات المحفوظة
        var userInfo = UserInfo(
          id: 0, // لا نحتاج user_id بعد الآن
          name: name,
          phone: phone,
          city: '', // يمكن إضافته لاحقاً
          address: near,
          password: '', // لا نحتاج كلمة المرور للعرض
          point: 0,
          active: 1,
        );
        
        userList.assignAll([userInfo]);
        profilePicUrl.value = profilePic;
        hasError.value = false;
        errorMessage.value = '';
      } else {
        hasError.value = true;
        errorMessage.value = 'User data not found in local storage';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'An error occurred: ${e.toString()}';
    } finally {
      isLoadingUser.value = false;
      update();
    }
  }

  // إعادة تحميل البيانات يدوياً
  void refreshProfile() {
    fetchProfile();
  }

  void openWhatsapp() async {
    WhatsAppHelper.openWhatsappForUserBranch();
  }

  void logout() {
    sharedPreferences?.clear();
    Get.offNamed('/');
  }

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
    fetchProfile();
  }

  @override
  void onReady() {
    super.onReady();
    // إعادة تحميل البيانات عند فتح الصفحة
    checkLoginStatus();
    fetchProfile();
  }

  @override
  void onClose() {
    // تنظيف البيانات عند إغلاق الصفحة
    userList.clear();
    super.onClose();
  }

  void deleteAccount() async {
    var name = sharedPreferences?.getString('name');
    var phone = sharedPreferences?.getString('phone');

    if (name == null || phone == null) {
      Get.snackbar('Error', 'User information not found');
      return;
    }

    await RemoteServices.deleteAccount(name, phone);
    sharedPreferences?.clear();
    BoxCart.clear();
    Get.off(() => Login());
  }
}
