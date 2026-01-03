import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/audio_service.dart';
import '../controllers/notification_controller.dart';
import '../controllers/branch_controller.dart';

class OrderController extends GetxController {
  // قائمة الطلبات
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<OrderModel> filteredOrders = <OrderModel>[].obs;
  
  // حالة التحميل
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // البحث والفلترة
  final RxString searchQuery = ''.obs;
  final RxInt selectedStatus = (-1).obs; // -1 = all, 0-4 = status codes
  final RxString sortBy = 'createdAt'.obs;
  final RxBool sortDescending = true.obs;
  
  // الإحصائيات
  final RxMap<String, int> stats = <String, int>{}.obs;
  final RxMap<String, dynamic> periodStats = <String, dynamic>{}.obs;
  
  // تتبع الطلبات الجديدة للإشعارات
  final RxList<String> processedOrderIds = <String>[].obs;
  final RxInt newOrdersCount = 0.obs;
  
  // خدمة الصوت
  final AudioService _audioService = AudioService();

  @override
  void onInit() {
    super.onInit();
    
    // تهيئة خدمة الصوت
    _audioService.initialize();
    
    // تحميل الطلبات بناءً على الفرع المختار
    final branchController = Get.find<BranchController>();
    fetchOrders(branch: branchController.selectedBranch.value);
    fetchStats();
    
    // الاستماع لتغييرات الفرع
    branchController.selectedBranch.listen((branch) {
      print('🔄 OrderController - تم تغيير الفرع إلى: $branch');
      fetchOrders(branch: branch);
      fetchStats();
    });
  }

  // جلب جميع الطلبات
  Future<void> fetchOrders({String? branch}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      print('🔄 OrderController - جلب الطلبات للفرع: ${branch ?? "الكل"}');
      
      final fetchedOrders = await OrderService.getAllOrders(branch: branch);
      orders.value = fetchedOrders;
      filteredOrders.value = fetchedOrders;
      
      // التحقق من الطلبات الجديدة
      await _checkForNewOrders(fetchedOrders);
      
      print('✅ OrderController - تم جلب ${fetchedOrders.length} طلب');
      
    } catch (e) {
      errorMessage.value = 'خطأ في جلب الطلبات: $e';
      print('❌ OrderController - خطأ في جلب الطلبات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب الطلبات حسب الحالة
  Future<void> fetchOrdersByStatus(int status, {String? branch}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      List<OrderModel> fetchedOrders;
      if (status == -1) {
        fetchedOrders = await OrderService.getAllOrders(branch: branch);
      } else {
        fetchedOrders = await OrderService.getOrdersByStatus(status, branch: branch);
      }
      
      orders.value = fetchedOrders;
      filteredOrders.value = fetchedOrders;
      
    } catch (e) {
      errorMessage.value = 'خطأ في جلب الطلبات: $e';
      print('❌ OrderController - خطأ في جلب الطلبات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب الإحصائيات
  Future<void> fetchStats() async {
    try {
      final fetchedStats = await OrderService.getOrderStats();
      stats.value = fetchedStats;
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
    }
  }

  // جلب إحصائيات الفترة
  Future<void> fetchPeriodStats(DateTime startDate, DateTime endDate) async {
    try {
      final fetchedStats = await OrderService.getOrderStatsForPeriod(startDate, endDate);
      periodStats.value = fetchedStats;
    } catch (e) {
      print('خطأ في جلب إحصائيات الفترة: $e');
    }
  }

  // البحث في الطلبات
  void searchOrders(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  // فلترة حسب الحالة
  void filterByStatus(int status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  // ترتيب الطلبات
  void sortOrders(String field, {bool descending = true}) {
    sortBy.value = field;
    sortDescending.value = descending;
    _applyFilters();
  }

  // تطبيق الفلاتر
  void _applyFilters() {
    List<OrderModel> filtered = List.from(orders);
    
    // فلترة حسب البحث
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((order) =>
        order.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        order.userPhone.contains(searchQuery.value) ||
        order.originalId.toString().contains(searchQuery.value) ||
        order.orderstatus.toLowerCase().contains(searchQuery.value.toLowerCase())
      ).toList();
    }
    
    // فلترة حسب الحالة
    if (selectedStatus.value != -1) {
      filtered = filtered.where((order) =>
        order.status == selectedStatus.value
      ).toList();
    }
    
    // ترتيب الطلبات
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy.value) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
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
    
    filteredOrders.value = filtered;
  }

  // تحديث حالة الطلب
  Future<bool> updateOrderStatus(String orderId, int newStatus, String newOrderStatus, {String? deliveryTime}) async {
    try {
      isLoading.value = true;
      
      print('بدء تحديث حالة الطلب: $orderId -> $newStatus ($newOrderStatus)');
      
      // الحصول على الطلب قبل التحديث
      final order = orders.firstWhere((o) => o.id == orderId);
      print('الطلب الحالي: ${order.name} - الحالة: ${order.status} (${order.orderstatus})');
      
      final success = await OrderService.updateOrderStatus(orderId, newStatus, newOrderStatus, deliveryTime: deliveryTime);
      print('نتيجة التحديث في Firebase: $success');
      
      if (success) {
        // تحديث الطلب محلياً
        final updatedOrder = order.copyWith(
          status: newStatus, 
          orderstatus: newOrderStatus,
          updatedAt: DateTime.now(),
          deliveryTime: deliveryTime, // إضافة تحديث وقت التوصيل
        );
        final index = orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          orders[index] = updatedOrder;
          print('تم تحديث الطلب محلياً في الفهرس: $index');
        }
        
        // تطبيق الفلاتر
        _applyFilters();
        print('تم تطبيق الفلاتر');
        
        // تحديث الإحصائيات
        await fetchStats();
        print('تم تحديث الإحصائيات');
        
        // إرسال إشعار للعميل فقط إذا تغيرت الحالة فعلاً
        if (order.status != newStatus) {
          await sendOrderStatusUpdateNotification(updatedOrder, newOrderStatus);
          print('تم إرسال الإشعار للعميل');
        }
        
        // تم إزالة إشعار النجاح
      } else {
        print('فشل في تحديث الطلب في Firebase');
      }
      
      return success;
    } catch (e) {
      print('خطأ في تحديث حالة الطلب: $e');
      // تم إزالة إشعار الخطأ
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // تحديث الطلب
  Future<bool> updateOrder(String orderId, Map<String, dynamic> data) async {
    try {
      isLoading.value = true;
      final success = await OrderService.updateOrder(orderId, data);
      
      if (success) {
        await fetchOrders();
        await fetchStats();
        // تم إزالة إشعار النجاح
      }
      
      return success;
    } catch (e) {
      // تم إزالة إشعار الخطأ
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // حذف الطلب
  Future<bool> deleteOrder(String orderId) async {
    try {
      isLoading.value = true;
      final success = await OrderService.deleteOrder(orderId);
      
      if (success) {
        await fetchOrders();
        await fetchStats();
        // تم إزالة إشعار النجاح
      }
      
      return success;
    } catch (e) {
      // تم إزالة إشعار الخطأ
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // إضافة طلب جديد
  Future<String?> addOrder(OrderModel order) async {
    try {
      isLoading.value = true;
      final orderId = await OrderService.addOrder(order);
      
      if (orderId != null) {
        await fetchOrders();
        await fetchStats();
        // تم إزالة إشعار النجاح
      }
      
      return orderId;
    } catch (e) {
      // تم إزالة إشعار الخطأ
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // مسح الفلاتر
  void clearFilters() {
    searchQuery.value = '';
    selectedStatus.value = -1;
    sortBy.value = 'createdAt';
    sortDescending.value = true;
    _applyFilters();
  }

  // تحديث البيانات
  Future<void> refresh({String? branch}) async {
    await fetchOrders(branch: branch);
    await fetchStats();
  }

  // الحصول على الطلبات حسب الحالة
  List<OrderModel> getOrdersByStatus(int status) {
    return orders.where((order) => order.status == status).toList();
  }

  // الحصول على إجمالي الإيرادات
  double get totalRevenue {
    return orders
        .where((order) => order.isDelivered)
        .fold(0.0, (sum, order) => sum + order.price);
  }

  // الحصول على متوسط قيمة الطلب
  double get averageOrderValue {
    final deliveredOrders = orders.where((order) => order.isDelivered).toList();
    if (deliveredOrders.isEmpty) return 0.0;
    return totalRevenue / deliveredOrders.length;
  }

  // الحصول على عدد الطلبات اليوم
  int get todayOrdersCount {
    final today = DateTime.now();
    return orders.where((order) {
      return order.createdAt.year == today.year &&
             order.createdAt.month == today.month &&
             order.createdAt.day == today.day;
    }).length;
  }

  // الحصول على إيرادات اليوم
  double get todayRevenue {
    final today = DateTime.now();
    return orders
        .where((order) {
          return order.isDelivered &&
                 order.createdAt.year == today.year &&
                 order.createdAt.month == today.month &&
                 order.createdAt.day == today.day;
        })
        .fold(0.0, (sum, order) => sum + order.price);
  }

  // التحقق من الطلبات الجديدة وإرسال الإشعارات
  Future<void> _checkForNewOrders(List<OrderModel> fetchedOrders) async {
    try {
      // البحث عن الطلبات الجديدة (التي لم يتم معالجتها من قبل)
      final newOrders = fetchedOrders.where((order) {
        return !processedOrderIds.contains(order.id) && 
               order.status == 0 && // جاري التجهيز
               order.createdAt.isAfter(DateTime.now().subtract(Duration(hours: 1))); // خلال آخر ساعة فقط
      }).toList();

      if (newOrders.isNotEmpty) {
        newOrdersCount.value = newOrders.length;
        
        // إرسال إشعار للداشبورد مرة واحدة فقط
        await _sendNewOrderNotification(newOrders);
        
        // إضافة معرفات الطلبات الجديدة إلى القائمة المعالجة
        for (var order in newOrders) {
          processedOrderIds.add(order.id);
        }
      }
    } catch (e) {
      print('خطأ في التحقق من الطلبات الجديدة: $e');
    }
  }

  // إرسال إشعار للطلبات الجديدة
  Future<void> _sendNewOrderNotification(List<OrderModel> newOrders) async {
    try {
      // تشغيل الصوت أولاً
      await _audioService.playNewOrderSound();
      
      // إظهار إشعار واحد فقط في الداشبورد
      Get.snackbar(
        'طلب جديد وصل!',
        'تم استلام ${newOrders.length} طلب جديد',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
        icon: Icon(Icons.shopping_cart, color: Colors.white),
        snackPosition: SnackPosition.TOP,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
        isDismissible: true,
        shouldIconPulse: true,
      );
      
    } catch (e) {
      print('خطأ في إرسال إشعار الطلبات الجديدة: $e');
    }
  }

  // إرسال إشعار عند تحديث حالة الطلب
  Future<void> sendOrderStatusUpdateNotification(OrderModel order, String newStatus) async {
    try {
      final notificationController = Get.find<NotificationController>();
      
      String title = '';
      String message = '';
      
      // إرسال إشعارات فقط للحالات المطلوبة
      switch (order.status) {
        case 1: // جاري التوصيل
          title = 'طلبك في الطريق 🚚';
          String deliveryTimeText = order.deliveryTime != null ? ' (${order.deliveryTime})' : '';
          message = 'طلبك رقم #${order.id.substring(0, 8)} في الطريق إليك الآن$deliveryTimeText';
          break;
        case 2: // تم الاستلام
          title = 'تم استلام طلبك ✅';
          message = 'تم استلام طلبك رقم #${order.id.substring(0, 8)} بنجاح. شكراً لك!';
          break;
        default:
          // لا نرسل إشعارات للحالات الأخرى
          return;
      }
      
      if (title.isNotEmpty && message.isNotEmpty) {
        print('📱 إرسال إشعار للمستخدم ${order.userPhone}: $title');
        
        await notificationController.sendToSpecificUser(
          phoneNumber: order.userPhone,
          title: title,
          message: message,
          data: {
            'type': 'order_status_update',
            'orderId': order.id,
            'status': order.status,
            'statusText': newStatus,
            'deliveryTime': order.deliveryTime,
          },
        );
        
        print('✅ تم إرسال الإشعار بنجاح للمستخدم ${order.userPhone}');
      }
    } catch (e) {
      print('❌ خطأ في إرسال إشعار تحديث حالة الطلب: $e');
    }
  }

  // مسح عداد الطلبات الجديدة
  void clearNewOrdersCount() {
    newOrdersCount.value = 0;
  }
  
  // اختبار الصوت
  Future<void> testSound() async {
    try {
      await _audioService.playNewOrderSound();
      Get.snackbar(
        'اختبار الصوت',
        'تم تشغيل صوت الإشعار',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
        icon: Icon(Icons.volume_up, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تشغيل الصوت: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
        icon: Icon(Icons.error, color: Colors.white),
      );
    }
  }
}
