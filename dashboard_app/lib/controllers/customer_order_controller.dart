import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/audio_service.dart';
import '../controllers/notification_controller.dart';
import '../controllers/branch_controller.dart';

class CustomerOrderController extends GetxController {
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxList<OrderModel> filteredOrders = <OrderModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxInt selectedStatus = (-1).obs;
  final RxString sortBy = 'createdAt'.obs;
  final RxBool sortDescending = true.obs;
  final RxMap<String, int> stats = <String, int>{}.obs;
  final RxList<String> processedOrderIds = <String>[].obs;
  final RxInt newOrdersCount = 0.obs;

  final AudioService _audioService = AudioService();
  StreamSubscription? _ordersListener;
  StreamSubscription<String>? _branchListener;
  Timer? _purgeTimer;

  bool get _isIraqBranch =>
      Get.find<BranchController>().selectedBranch.value == 'العراق';

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
    _audioService.initialize();
    fetchOrders();
    fetchStats();
    _startListener();
    _branchListener = Get.find<BranchController>().selectedBranch.listen((_) {
      fetchOrders();
      fetchStats();
      _startListener();
    });
    _purgeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (isClosed) return;
      OrderService.purgeExpiredCancelledOrders().then((_) {
        if (!isClosed) {
          fetchOrders(showLoading: false);
          fetchStats();
        }
      });
    });
  }

  @override
  void onClose() {
    _purgeTimer?.cancel();
    _ordersListener?.cancel();
    _branchListener?.cancel();
    super.onClose();
  }

  void _startListener() {
    _ordersListener?.cancel();
    if (!_isIraqBranch) return;
    _ordersListener = OrderService.listenToNewCustomerOrders(
      onNewOrder: _onNewOrderReceived,
    );
  }

  Future<void> _onNewOrderReceived(OrderModel order) async {
    if (!_isIraqBranch) return;
    if (processedOrderIds.contains(order.id)) return;
    processedOrderIds.add(order.id);
    newOrdersCount.value = newOrdersCount.value + 1;
    await _audioService.playNewOrderSound();
    Get.snackbar(
      'طلب زبون جديد',
      'طلب جديد من ${order.name}',
      backgroundColor: Colors.teal,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      icon: const Icon(Icons.person, color: Colors.white),
      snackPosition: SnackPosition.TOP,
    );
    if (!orders.any((o) => o.id == order.id)) {
      orders.insert(0, order);
      _applyFilters();
    }
    fetchStats();
  }

  Future<void> fetchOrders({bool showLoading = true}) async {
    try {
      if (showLoading && !selectionMode.value && selectedOrderIds.isEmpty) {
        isLoading.value = true;
      }
      errorMessage.value = '';
      if (!_isIraqBranch) {
        orders.clear();
        filteredOrders.clear();
        newOrdersCount.value = 0;
        return;
      }
      final fetched = _uniqueOrdersById(await OrderService.getCustomerOrders());
      orders.value = fetched;
      filteredOrders.value = fetched;
      _pruneSelectionToVisible();
    } catch (e) {
      errorMessage.value = 'خطأ في جلب طلبات الزبائن: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStats() async {
    try {
      if (!_isIraqBranch) {
        stats.value = {
          'total': 0,
          'preparing': 0,
          'delivering': 0,
          'delivered': 0,
          'cancelled': 0,
        };
        return;
      }
      stats.value = await OrderService.getCustomerOrderStats();
    } catch (e) {
      print('خطأ في إحصائيات طلبات الزبائن: $e');
    }
  }

  void searchOrders(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void filterByStatus(int status) {
    selectedStatus.value = status;
    _applyFilters();
  }

  void sortOrders(String field, {bool descending = true}) {
    sortBy.value = field;
    sortDescending.value = descending;
    _applyFilters();
  }

  void _applyFilters() {
    List<OrderModel> filtered = List.from(orders);
    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      filtered = filtered
          .where((order) =>
              order.name.toLowerCase().contains(q) ||
              order.userPhone.contains(searchQuery.value) ||
              order.originalId.toString().contains(searchQuery.value) ||
              order.orderstatus.toLowerCase().contains(q))
          .toList();
    }
    if (selectedStatus.value != -1) {
      filtered =
          filtered.where((o) => o.status == selectedStatus.value).toList();
    }
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
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return sortDescending.value ? -comparison : comparison;
    });
    filteredOrders.value = filtered;
  }

  Future<bool> updateOrderStatus(
    String orderId,
    int newStatus,
    String newOrderStatus, {
    String? deliveryTime,
    String? customerMessage,
    int? deliveryDurationMinutes,
    DateTime? deliveryDeadlineAt,
  }) async {
    try {
      isLoading.value = true;
      final order = orders.firstWhere((o) => o.id == orderId);
      final success = await OrderService.updateOrderStatus(
        orderId,
        newStatus,
        newOrderStatus,
        deliveryTime: deliveryTime,
        customerMessage: customerMessage,
        deliveryDurationMinutes: deliveryDurationMinutes,
        deliveryDeadlineAt: deliveryDeadlineAt,
      );
      if (success) {
        final index = orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          orders[index] = order.copyWith(
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
        }
        _applyFilters();
        await fetchStats();
        final updated = orders.firstWhere((o) => o.id == orderId);
        if (order.status != newStatus) {
          await _sendStatusNotification(updated);
        } else if (customerMessage != null &&
            customerMessage.trim().isNotEmpty &&
            customerMessage.trim() != (order.customerMessage ?? '')) {
          await _sendCustomerMessageNotification(updated, customerMessage.trim());
        } else if (deliveryDurationMinutes != null &&
            deliveryDurationMinutes != order.deliveryDurationMinutes) {
          await _sendStatusNotification(updated);
        }
      }
      return success;
    } catch (e) {
      print('خطأ تحديث طلب زبون: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _sendStatusNotification(OrderModel order) async {
    try {
      final notificationController = Get.find<NotificationController>();
      String title = '';
      String message = '';
      switch (order.status) {
        case 1:
          title = 'طلبك في الطريق 🚚';
          final msg = (order.deliveryTime ?? '').trim();
          final extra = msg.isNotEmpty ? '\nوقت التوصيل المتوقع: $msg' : '';
          message =
              'طلبك رقم #${order.originalId} في الطريق إليك الآن$extra';
          break;
        case 2:
          title = 'تم استلام طلبك ✅';
          message =
              'تم استلام طلبك رقم #${order.originalId} بنجاح. شكراً لك!';
          break;
        default:
          return;
      }
      await notificationController.sendToSpecificUser(
        phoneNumber: order.userPhone,
        title: title,
        message: message,
        data: {
          'type': 'order_status_update',
          'orderId': order.id,
          'status': order.status,
        },
      );
    } catch (e) {
      print('إشعار طلب زبون: $e');
    }
  }

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
      print('إشعار رسالة زبون: $e');
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      isLoading.value = true;
      final success = await OrderService.deleteOrder(orderId);
      if (success) {
        await fetchOrders();
        await fetchStats();
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedStatus.value = -1;
    sortBy.value = 'createdAt';
    sortDescending.value = true;
    _applyFilters();
  }

  void clearNewOrdersCount() {
    newOrdersCount.value = 0;
  }

  Future<void> refresh() async {
    await fetchOrders(showLoading: false);
    await fetchStats();
  }

  Future<void> testSound() async {
    await _audioService.playNewOrderSound();
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

  Future<int> deleteSelectedOrders() async {
    if (selectedOrderIds.isEmpty) return 0;
    try {
      isBulkWorking.value = true;
      final ids = List<String>.from(selectedOrderIds);
      final deleted = await OrderService.deleteOrders(ids);
      if (deleted > 0) {
        exitSelectionMode();
        await fetchOrders(showLoading: false);
        await fetchStats();
        Get.snackbar(
          'تم الحذف',
          'تم حذف $deleted طلب زبون',
          backgroundColor: Colors.teal,
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
          await _sendStatusNotification(updatedOrder);
        }
        exitSelectionMode();
        await fetchOrders(showLoading: false);
        await fetchStats();
        Get.snackbar(
          'تم التحديث',
          'تم تغيير حالة $updated طلب إلى "$newOrderStatus"',
          backgroundColor: Colors.teal,
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
}
