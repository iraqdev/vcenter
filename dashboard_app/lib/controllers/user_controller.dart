import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'branch_controller.dart';

class UserController extends GetxController {
  final RxList<UserModel> allUsers = <UserModel>[].obs;
  final RxList<UserModel> newUsers = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingNewUsers = false.obs;
  final RxString searchQuery = ''.obs;
  final RxMap<String, int> userStats = <String, int>{}.obs;
  
  // متغيرات لتتبع المستخدمين الجدد
  final RxList<String> processedUserIds = <String>[].obs;
  final RxInt newUsersCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final branchController = Get.find<BranchController>();
    loadAllUsers(branch: branchController.selectedBranch.value);
    loadNewUsers();
    loadUserStats(branch: branchController.selectedBranch.value);
    
    // الاستماع لتغيير الفرع
    branchController.selectedBranch.listen((branch) {
      print('🔄 UserController - تم تغيير الفرع إلى: $branch');
      loadAllUsers(branch: branch);
      loadUserStats(branch: branch);
    });
  }

  // جلب جميع المستخدمين (مع فلترة حسب الفرع)
  Future<void> loadAllUsers({String? branch}) async {
    isLoading.value = true;
    try {
      final users = await UserService.getAllUsers(branch: branch);
      allUsers.assignAll(users);
      
      // التحقق من المستخدمين الجدد
      await _checkForNewUsers(users);
      
      print('✅ UserController - تم جلب ${users.length} مستخدم للفرع: ${branch ?? "الكل"}');
    } catch (e) {
      // تم إزالة إشعار الخطأ
    } finally {
      isLoading.value = false;
    }
  }

  // جلب المستخدمين الجدد (بدون فلترة - عرض الكل)
  Future<void> loadNewUsers() async {
    isLoadingNewUsers.value = true;
    try {
      final users = await UserService.getNewUsers();
      newUsers.assignAll(users);
      print('✅ UserController - تم جلب ${users.length} حساب جديد');
    } catch (e) {
      // تم إزالة إشعار الخطأ
    } finally {
      isLoadingNewUsers.value = false;
    }
  }

  // جلب إحصائيات المستخدمين (مع فلترة حسب الفرع)
  Future<void> loadUserStats({String? branch}) async {
    try {
      final stats = await UserService.getUserStats(branch: branch);
      userStats.assignAll(stats);
    } catch (e) {
      print('❌ UserController - خطأ في جلب الإحصائيات: $e');
    }
  }

  // تحديث حالة المراجعة
  Future<void> markAsReviewed(String userId) async {
    try {
      final success = await UserService.markAsReviewed(userId);
      if (success) {
        // إزالة المستخدم من قائمة المستخدمين الجدد
        newUsers.removeWhere((user) => user.id == userId);
        // تحديث المستخدم في القائمة الرئيسية
        final index = allUsers.indexWhere((user) => user.id == userId);
        if (index != -1) {
          allUsers[index] = allUsers[index].copyWith(isReviewed: true);
        }
        // تحديث الإحصائيات
        loadUserStats();
        // تم إزالة إشعار النجاح
      } else {
        // تم إزالة إشعار الخطأ
      }
    } catch (e) {
      // تم إزالة إشعار الخطأ
    }
  }

  // تحديث حالة التفعيل/الحظر
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      final success = await UserService.updateUserStatus(userId, isActive);
      if (success) {
        // تحديث المستخدم في القائمة الرئيسية
        final index = allUsers.indexWhere((user) => user.id == userId);
        if (index != -1) {
          allUsers[index] = allUsers[index].copyWith(isActive: isActive);
        }
        // تحديث المستخدم في قائمة المستخدمين الجدد إذا كان موجوداً
        final newIndex = newUsers.indexWhere((user) => user.id == userId);
        if (newIndex != -1) {
          newUsers[newIndex] = newUsers[newIndex].copyWith(isActive: isActive);
        }
        // تحديث الإحصائيات
        loadUserStats();
        // تم إزالة إشعار النجاح
      } else {
        // تم إزالة إشعار الخطأ
      }
    } catch (e) {
      // تم إزالة إشعار الخطأ
    }
  }

  // تحديث معلومات المستخدم
  Future<void> updateUser(UserModel user) async {
    try {
      final success = await UserService.updateUser(user.id, user);
      if (success) {
        // تحديث المستخدم في القائمة الرئيسية
        final index = allUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          allUsers[index] = user;
        }
        // تحديث المستخدم في قائمة المستخدمين الجدد إذا كان موجوداً
        final newIndex = newUsers.indexWhere((u) => u.id == user.id);
        if (newIndex != -1) {
          newUsers[newIndex] = user;
        }
        // تم إزالة إشعار النجاح
      } else {
        // تم إزالة إشعار الخطأ
      }
    } catch (e) {
      // تم إزالة إشعار الخطأ
    }
  }

  // حذف المستخدم
  Future<void> deleteUser(String userId) async {
    try {
      final success = await UserService.deleteUser(userId);
      if (success) {
        // إزالة المستخدم من القوائم
        allUsers.removeWhere((user) => user.id == userId);
        newUsers.removeWhere((user) => user.id == userId);
        // تحديث الإحصائيات
        loadUserStats();
        // تم إزالة إشعار النجاح
      } else {
        // تم إزالة إشعار الخطأ
      }
    } catch (e) {
      // تم إزالة إشعار الخطأ
    }
  }

  // البحث في المستخدمين
  Future<void> searchUsers(String query) async {
    searchQuery.value = query;
    if (query.isEmpty) {
      loadAllUsers();
      return;
    }

    isLoading.value = true;
    try {
      final users = await UserService.searchUsers(query);
      allUsers.assignAll(users);
    } catch (e) {
      // تم إزالة إشعار الخطأ
    } finally {
      isLoading.value = false;
    }
  }

  // إعادة تحميل البيانات
  Future<void> refreshData() async {
    await Future.wait([
      loadAllUsers(),
      loadNewUsers(),
      loadUserStats(),
    ]);
  }

  // فلترة المستخدمين حسب الحالة
  List<UserModel> get activeUsers => 
      allUsers.where((user) => user.isActive).toList();
  
  List<UserModel> get inactiveUsers => 
      allUsers.where((user) => !user.isActive).toList();
  
  List<UserModel> get reviewedUsers => 
      allUsers.where((user) => user.isReviewed).toList();

  // التحقق من المستخدمين الجدد
  Future<void> _checkForNewUsers(List<UserModel> fetchedUsers) async {
    try {
      final newUsers = fetchedUsers.where((user) {
        return !processedUserIds.contains(user.id) && 
               !user.isReviewed && // غير مراجع
               user.createdAt.isAfter(DateTime.now().subtract(Duration(hours: 1))); // خلال آخر ساعة فقط
      }).toList();

      if (newUsers.isNotEmpty) {
        newUsersCount.value = newUsers.length;
        await _sendNewUserNotification(newUsers);
        for (var user in newUsers) {
          processedUserIds.add(user.id);
        }
      }
    } catch (e) {
      print('خطأ في التحقق من المستخدمين الجدد: $e');
    }
  }

  // إرسال إشعار للمستخدمين الجدد
  Future<void> _sendNewUserNotification(List<UserModel> newUsers) async {
    try {
      // إظهار إشعار واحد فقط في الداشبورد
      Get.snackbar(
        'مستخدم جديد انضم!',
        'انضم ${newUsers.length} مستخدم جديد',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
        icon: Icon(Icons.person_add, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
        isDismissible: true,
        shouldIconPulse: true,
        onTap: (snack) {
          // انتقال إلى شاشة المستخدمين الجدد عند الضغط على الإشعار
          Get.toNamed('/new-users');
        },
      );
      
    } catch (e) {
      print('خطأ في إرسال إشعار المستخدمين الجدد: $e');
    }
  }

  // مسح عداد المستخدمين الجدد
  void clearNewUsersCount() {
    newUsersCount.value = 0;
  }
}
