import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxList<NotificationModel> filteredNotifications = <NotificationModel>[].obs;

  // حالة التحميل
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // البحث والفلترة
  final RxString searchQuery = ''.obs;
  final RxString selectedType = 'all'.obs; // 'all', 'all_users', 'specific', 'offer', 'promotion'
  final RxString selectedStatus = 'all'.obs; // 'all', 'draft', 'scheduled', 'sent', 'failed'
  final RxString sortBy = 'createdAt'.obs;
  final RxBool sortDescending = true.obs;

  // الإحصائيات
  final RxMap<String, int> stats = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    fetchStats();
  }

  // جلب جميع الإشعارات
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final fetchedNotifications = await NotificationService.getAllNotifications();
      notifications.value = fetchedNotifications;
      _applyFilters();

    } catch (e) {
      errorMessage.value = 'خطأ في جلب الإشعارات: $e';
      print('خطأ في جلب الإشعارات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب الإشعارات حسب النوع
  Future<void> fetchNotificationsByType(String type) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      List<NotificationModel> fetchedNotifications;
      if (type == 'all') {
        fetchedNotifications = await NotificationService.getAllNotifications();
      } else {
        fetchedNotifications = await NotificationService.getNotificationsByType(type);
      }

      notifications.value = fetchedNotifications;
      filteredNotifications.value = fetchedNotifications;

    } catch (e) {
      errorMessage.value = 'خطأ في جلب الإشعارات: $e';
      print('خطأ في جلب الإشعارات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب الإحصائيات
  Future<void> fetchStats() async {
    try {
      final fetchedStats = await NotificationService.getNotificationStats();
      stats.value = fetchedStats;
    } catch (e) {
      print('خطأ في جلب إحصائيات الإشعارات: $e');
    }
  }

  // البحث في الإشعارات
  void searchNotifications(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  // فلترة حسب النوع
  void filterByType(String type) {
    selectedType.value = type;
    _applyFilters();
  }

  // فلترة حسب الحالة
  void filterByStatus(String status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  // ترتيب الإشعارات
  void sortNotifications(String field, {bool descending = true}) {
    sortBy.value = field;
    sortDescending.value = descending;
    _applyFilters();
  }

  // تطبيق الفلاتر
  void _applyFilters() {
    List<NotificationModel> filtered = List.from(notifications);

    // فلترة حسب البحث
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((notification) =>
          notification.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          notification.message.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          notification.type.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          (notification.targetPhone?.contains(searchQuery.value) ?? false)
      ).toList();
    }

    // فلترة حسب النوع
    if (selectedType.value != 'all') {
      if (selectedType.value == 'all_users') {
        filtered = filtered.where((notification) => notification.isForAllUsers).toList();
      } else {
        filtered = filtered.where((notification) => notification.type == selectedType.value).toList();
      }
    }

    // فلترة حسب الحالة
    if (selectedStatus.value != 'all') {
      filtered = filtered.where((notification) => notification.status == selectedStatus.value).toList();
    }

    // ترتيب الإشعارات
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortBy.value) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'type':
          comparison = a.type.compareTo(b.type);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'createdAt':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }

      return sortDescending.value ? -comparison : comparison;
    });

    filteredNotifications.value = filtered;
  }

  // إرسال إشعار لجميع المستخدمين
  Future<Map<String, dynamic>> sendToAllUsers({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
    String? branch, // فلترة حسب الفرع
  }) async {
    try {
      isLoading.value = true;
      final result = await NotificationService.sendToAllUsers(
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
        branch: branch, // تمرير معامل الفرع
      );

      if (result['success']) {
        await fetchNotifications();
        await fetchStats();
        // تم إزالة إشعار النجاح
      } else {
        // تم إزالة إشعار الخطأ
      }

      return result;
    } catch (e) {
      // تم إزالة إشعار الخطأ
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار: $e',
        'sentCount': 0,
        'failedCount': 0,
      };
    } finally {
      isLoading.value = false;
    }
  }

  // إرسال إشعار لمستخدم محدد
  Future<Map<String, dynamic>> sendToSpecificUser({
    required String phoneNumber,
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      isLoading.value = true;
      final result = await NotificationService.sendToSpecificUser(
        phoneNumber: phoneNumber,
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );

      if (result['success']) {
        await fetchNotifications();
        await fetchStats();
        Get.snackbar(
          'نجح',
          'تم إرسال الإشعار للمستخدم بنجاح',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        // تم إزالة إشعار الخطأ
      }

      return result;
    } catch (e) {
      // تم إزالة إشعار الخطأ
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار: $e',
        'sentCount': 0,
        'failedCount': 1,
      };
    } finally {
      isLoading.value = false;
    }
  }

  // إرسال إشعار ترويجي
  Future<Map<String, dynamic>> sendPromotionalNotification({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
    String? targetPhone,
  }) async {
    try {
      isLoading.value = true;
      final result = await NotificationService.sendPromotionalNotification(
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
        targetPhone: targetPhone,
      );

      if (result['success']) {
        await fetchNotifications();
        await fetchStats();
        Get.snackbar(
          'نجح',
          'تم إرسال الإشعار الترويجي بنجاح',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        // تم إزالة إشعار الخطأ
      }

      return result;
    } catch (e) {
      // تم إزالة إشعار الخطأ
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار: $e',
        'sentCount': 0,
        'failedCount': 0,
      };
    } finally {
      isLoading.value = false;
    }
  }

  // حذف إشعار
  Future<bool> deleteNotification(String notificationId) async {
    try {
      isLoading.value = true;
      final success = await NotificationService.deleteNotification(notificationId);

      if (success) {
        await fetchNotifications();
        await fetchStats();
        Get.snackbar(
          'نجح',
          'تم حذف الإشعار بنجاح',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      }

      return success;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حذف الإشعار: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // مسح الفلاتر
  void clearFilters() {
    searchQuery.value = '';
    selectedType.value = 'all';
    selectedStatus.value = 'all';
    sortBy.value = 'createdAt';
    sortDescending.value = true;
    _applyFilters();
  }

  // تحديث البيانات
  Future<void> refresh() async {
    await fetchNotifications();
    await fetchStats();
  }

  // اختبار OneSignal مباشرة
  Future<Map<String, dynamic>> testOneSignalDirectly() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await NotificationService.testOneSignalDirectly();
      
      return result;
      
    } catch (e) {
      errorMessage.value = 'خطأ في اختبار OneSignal: $e';
      print('خطأ في اختبار OneSignal: $e');
      return {
        'success': false,
        'message': 'خطأ في اختبار OneSignal: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // إرسال إشعار مخصص لجميع المستخدمين
  Future<Map<String, dynamic>> sendCustomNotificationToAll({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await NotificationService.sendCustomNotificationToAll(
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );
      
      return result;
      
    } catch (e) {
      errorMessage.value = 'خطأ في إرسال الإشعار المخصص: $e';
      print('خطأ في إرسال الإشعار المخصص: $e');
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار المخصص: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // إرسال إشعار مخصص لمستخدم محدد
  Future<Map<String, dynamic>> sendCustomNotificationToSpecificUser({
    required String phoneNumber,
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await NotificationService.sendCustomNotificationToSpecificUser(
        phoneNumber: phoneNumber,
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );
      
      return result;
      
    } catch (e) {
      errorMessage.value = 'خطأ في إرسال الإشعار المخصص للمستخدم المحدد: $e';
      print('خطأ في إرسال الإشعار المخصص للمستخدم المحدد: $e');
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار المخصص للمستخدم المحدد: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // اختبار مستخدم محدد
  Future<Map<String, dynamic>> testSpecificUser({
    required String phoneNumber,
    required String title,
    required String message,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await NotificationService.testSpecificUser(
        phoneNumber: phoneNumber,
        title: title,
        message: message,
      );
      
      return result;
      
    } catch (e) {
      errorMessage.value = 'خطأ في اختبار المستخدم المحدد: $e';
      print('خطأ في اختبار المستخدم المحدد: $e');
      return {
        'success': false,
        'message': 'خطأ في اختبار المستخدم المحدد: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // فحص جميع المستخدمين
  Future<Map<String, dynamic>> debugAllUsers() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await NotificationService.debugAllUsers();
      
      return result;
      
    } catch (e) {
      errorMessage.value = 'خطأ في فحص المستخدمين: $e';
      print('خطأ في فحص المستخدمين: $e');
      return {
        'success': false,
        'message': 'خطأ في فحص المستخدمين: $e',
      };
    } finally {
      isLoading.value = false;
    }
  }

  // الحصول على الإشعارات حسب النوع
  List<NotificationModel> getNotificationsByType(String type) {
    return notifications.where((notification) => notification.type == type).toList();
  }

  // الحصول على الإشعارات حسب الحالة
  List<NotificationModel> getNotificationsByStatus(String status) {
    return notifications.where((notification) => notification.status == status).toList();
  }

  // الحصول على إجمالي الإشعارات المرسلة
  int get totalSentNotifications {
    return notifications.where((notification) => notification.isSent).length;
  }

  // الحصول على إجمالي الإشعارات الفاشلة
  int get totalFailedNotifications {
    return notifications.where((notification) => notification.isFailed).length;
  }

  // الحصول على معدل نجاح الإشعارات
  double get successRate {
    final total = notifications.length;
    if (total == 0) return 0.0;
    return (totalSentNotifications / total) * 100;
  }
}
