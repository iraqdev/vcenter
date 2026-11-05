import 'dart:async';

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

  StreamSubscription? _ordersListener;
  Timer? _purgeTimer;

  /// إزالة أي تكرار لنفس مستند Firestore (نفس [OrderModel.id]) في القائمة المعروضة.
  List<OrderModel> _uniqueOrdersById(List<OrderModel> list) {
    final byId = <String, OrderModel>{};
    for (final o in list) {
      byId[o.id] = o;
    }
    final out = byId.values.toList();
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  @override
  void onInit() {
    super.onInit();
    
    // تهيئة خدمة الصوت
    _audioService.initialize();
    
    // تحميل الطلبات بناءً على الفرع المختار
    final branchController = Get.find<BranchController>();
    fetchOrders(branch: branchController.selectedBranch.value);
    fetchStats();
    _startOrdersListener(branchController.selectedBranch.value);
    _purgeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isClosed) return;
      final branch = Get.find<BranchController>().selectedBranch.value;
      OrderService.purgeExpiredCancelledOrders().then((_) {
        if (!isClosed) fetchOrders(branch: branch, showLoading: false);
      });
    });
    
    // الاستماع لتغييرات الفرع
    branchController.selectedBranch.listen((branch) {
      print('🔄 OrderController - تم تغيير الفرع إلى: $branch');
      exitSelectionMode();
      fetchOrders(branch: branch);
      fetchStats();
      _startOrdersListener(branch);
    });
  }

  @override
  void onClose() {
    _purgeTimer?.cancel();
    _ordersListener?.cancel();
    super.onClose();
  }

  void _startOrdersListener(String branch) {
    _ordersListener?.cancel();
    _ordersListener = OrderService.listenToNewOrders(
      branch: branch,
      onNewOrder: (order, branchName) => _onNewOrderReceived(order, branchName),
    );
  }

  /// طلب جديد من الاستماع الفوري: لا نضيف نفس [order.id] مرتين (كان يسبب تكراراً مع [fetchOrders]).
  Future<void> _onNewOrderReceived(OrderModel order, String branchName) async {
    if (processedOrderIds.contains(order.id)) return;
    processedOrderIds.add(order.id);

    newOrdersCount.value = newOrdersCount.value + 1;

    await _audioService.playNewOrderSound();

    Get.snackbar(
      '$branchName لديك طلب جديد',
      'تم استلام طلب جديد من ${order.name}',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.shopping_cart, color: Colors.white),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      shouldIconPulse: true,
    );

    if (!orders.any((o) => o.id == order.id)) {
      orders.insert(0, order);
      _applyFilters();
    }
    fetchStats();
  }

  // جلب جميع الطلبات
  Future<void> fetchOrders({String? branch, bool showLoading = true}) async {
    try {
      // لا نخفي القائمة أثناء وضع التحديد أو التحديث الصامت
      if (showLoading && !selectionMode.value && selectedOrderIds.isEmpty) {
        isLoading.value = true;
      }
      errorMessage.value = '';
      
      print('🔄 OrderController - جلب الطلبات للفرع: ${branch ?? "الكل"}');
      
      final raw = await OrderService.getAllOrders(branch: branch);
      final fetchedOrders = _uniqueOrdersById(raw);
      orders.value = fetchedOrders;
      filteredOrders.value = fetchedOrders;
      _pruneSelectionToVisible();
      
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

      fetchedOrders = _uniqueOrdersById(fetchedOrders);
      orders.value = fetchedOrders;
      filteredOrders.value = fetchedOrders;
      
    } catch (e) {
      errorMessage.value = 'خطأ في جلب الطلبات: $e';
      print('❌ OrderController - خطأ في جلب الطلبات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب الإحصائيات (حسب الفرع المختار)
  Future<void> fetchStats() async {
    try {
      final branchController = Get.find<BranchController>();
      final branch = branchController.selectedBranch.value;
      final fetchedStats = await OrderService.getOrderStats(branch: branch);
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
  Future<bool> updateOrderStatus(String orderId, int newStatus, String newOrderStatus, {String? deliveryTime, String? customerMessage, int? deliveryDurationMinutes, DateTime? deliveryDeadlineAt}) async {
    try {
      isLoading.value = true;
      
      print('بدء تحديث حالة الطلب: $orderId -> $newStatus ($newOrderStatus)');
      
      // الحصول على الطلب قبل التحديث
      final order = orders.firstWhere((o) => o.id == orderId);
      print('الطلب الحالي: ${order.name} - الحالة: ${order.status} (${order.orderstatus})');
      
      final success = await OrderService.updateOrderStatus(
        orderId,
        newStatus,
        newOrderStatus,
        deliveryTime: deliveryTime,
        customerMessage: customerMessage,
        deliveryDurationMinutes: deliveryDurationMinutes,
        deliveryDeadlineAt: deliveryDeadlineAt,
      );
      print('نتيجة التحديث في Firebase: $success');
      
      if (success) {
        // تحديث الطلب محلياً
        final updatedOrder = order.copyWith(
          status: newStatus, 
          orderstatus: newOrderStatus,
          updatedAt: DateTime.now(),
          deliveryTime: deliveryTime ?? order.deliveryTime,
          customerMessage: customerMessage?.trim().isEmpty == true
              ? null
              : (customerMessage ?? order.customerMessage),
          deliveryDurationMinutes:
              deliveryDurationMinutes ?? order.deliveryDurationMinutes,
          deliveryDeadlineAt: deliveryDeadlineAt ?? order.deliveryDeadlineAt,
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
        } else if (customerMessage != null &&
            customerMessage.trim().isNotEmpty &&
            customerMessage.trim() != (order.customerMessage ?? '')) {
          await _sendCustomerMessageNotification(updatedOrder, customerMessage.trim());
        } else if (deliveryDurationMinutes != null &&
            deliveryDurationMinutes != order.deliveryDurationMinutes) {
          await sendOrderStatusUpdateNotification(updatedOrder, newOrderStatus);
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
    await fetchOrders(branch: branch, showLoading: false);
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

  // إرسال إشعار برسالة مخصصة للعميل (بدون تغيير الحالة)
  Future<void> _sendCustomerMessageNotification(
    OrderModel order,
    String message,
  ) async {
    try {
      final notificationController = Get.find<NotificationController>();
      await notificationController.sendToSpecificUser(
        phoneNumber: order.userPhone,
        title: 'تحديث على طلبك 📋',
        message: message,
        data: {
          'type': 'order_customer_message',
          'orderId': order.id,
          'customerMessage': message,
        },
      );
    } catch (e) {
      print('❌ خطأ في إرسال رسالة العميل: $e');
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
          final msg = (order.deliveryTime ?? '').trim();
          final extra = msg.isNotEmpty ? '\nوقت التوصيل المتوقع: $msg' : '';
          message = 'طلبك رقم #${order.id.substring(0, 8)} في الطريق إليك الآن$extra';
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
            'customerMessage': order.customerMessage,
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

  // --- تحديد متعدد وحذف جماعي ---
  final RxBool selectionMode = false.obs;
  final RxList<String> selectedOrderIds = <String>[].obs;
  final RxBool isBulkWorking = false.obs;

  int get selectedCount => selectedOrderIds.length;

  bool isOrderSelected(String orderId) => selectedOrderIds.contains(orderId);

  void toggleSelectionMode() {
    selectionMode.value = !selectionMode.value;
    if (!selectionMode.value) {
      selectedOrderIds.clear();
    }
    selectedOrderIds.refresh();
  }

  void exitSelectionMode() {
    selectionMode.value = false;
    selectedOrderIds.clear();
    selectedOrderIds.refresh();
  }

  void toggleOrderSelection(String orderId) {
    if (orderId.isEmpty) return;
    if (selectedOrderIds.contains(orderId)) {
      selectedOrderIds.remove(orderId);
    } else {
      selectedOrderIds.add(orderId);
    }
    // ضمان إعادة بناء الواجهة فوراً
    selectedOrderIds.refresh();
  }

  void selectAllVisible() {
    selectedOrderIds.assignAll(
      filteredOrders.map((o) => o.id).where((id) => id.isNotEmpty),
    );
    selectedOrderIds.refresh();
  }

  void clearSelectedOrders() {
    selectedOrderIds.clear();
    selectedOrderIds.refresh();
  }

  void _pruneSelectionToVisible() {
    if (selectedOrderIds.isEmpty) return;
    final visibleIds = orders.map((o) => o.id).toSet();
    selectedOrderIds.removeWhere((id) => !visibleIds.contains(id));
    selectedOrderIds.refresh();
  }

  Future<int> deleteSelectedOrders({String? branch}) async {
    if (selectedOrderIds.isEmpty) return 0;
    try {
      isBulkWorking.value = true;
      final ids = List<String>.from(selectedOrderIds);
      final deleted = await OrderService.deleteOrders(ids);
      if (deleted > 0) {
        exitSelectionMode();
        await fetchOrders(branch: branch, showLoading: false);
        await fetchStats();
        Get.snackbar(
          'تم الحذف',
          'تم حذف $deleted طلب',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      return deleted;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حذف الطلبات: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      return 0;
    } finally {
      isBulkWorking.value = false;
    }
  }

  Future<int> updateSelectedOrdersStatus({
    required int newStatus,
    required String newOrderStatus,
    String? branch,
    String? deliveryTime,
    int? deliveryDurationMinutes,
    DateTime? deliveryDeadlineAt,
  }) async {
    if (selectedOrderIds.isEmpty) return 0;
    try {
      isBulkWorking.value = true;
      final ids = List<String>.from(selectedOrderIds);
      final selectedOrders =
          orders.where((o) => ids.contains(o.id)).toList();
      final updated = await OrderService.updateOrdersStatus(
        ids,
        newStatus,
        newOrderStatus,
        deliveryTime: deliveryTime,
        deliveryDurationMinutes: deliveryDurationMinutes,
        deliveryDeadlineAt: deliveryDeadlineAt,
      );
      if (updated > 0) {
        for (final order in selectedOrders) {
          if (order.status == newStatus &&
              deliveryDurationMinutes == null) {
            continue;
          }
          final updatedOrder = order.copyWith(
            status: newStatus,
            orderstatus: newOrderStatus,
            updatedAt: DateTime.now(),
            deliveryTime: deliveryTime ?? order.deliveryTime,
            deliveryDurationMinutes:
                deliveryDurationMinutes ?? order.deliveryDurationMinutes,
            deliveryDeadlineAt:
                deliveryDeadlineAt ?? order.deliveryDeadlineAt,
          );
          await sendOrderStatusUpdateNotification(updatedOrder, newOrderStatus);
        }
        exitSelectionMode();
        await fetchOrders(branch: branch, showLoading: false);
        await fetchStats();
        Get.snackbar(
          'تم التحديث',
          'تم تغيير حالة $updated طلب إلى "$newOrderStatus"',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      return updated;
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث حالة الطلبات: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      return 0;
    } finally {
      isBulkWorking.value = false;
    }
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
