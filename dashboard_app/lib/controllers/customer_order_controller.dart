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
  }

  @override
  void onClose() {
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

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;
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
  }) async {
    try {
      isLoading.value = true;
      final order = orders.firstWhere((o) => o.id == orderId);
      final success = await OrderService.updateOrderStatus(
        orderId,
        newStatus,
        newOrderStatus,
        deliveryTime: deliveryTime,
      );
      if (success) {
        final index = orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          orders[index] = order.copyWith(
            status: newStatus,
            orderstatus: newOrderStatus,
            updatedAt: DateTime.now(),
            deliveryTime: deliveryTime,
          );
        }
        _applyFilters();
        await fetchStats();
        if (order.status != newStatus) {
          await _sendStatusNotification(orders.firstWhere((o) => o.id == orderId));
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
          final t = order.deliveryTime != null ? ' (${order.deliveryTime})' : '';
          message =
              'طلبك رقم #${order.originalId} في الطريق إليك الآن$t';
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
    await fetchOrders();
    await fetchStats();
  }

  Future<void> testSound() async {
    await _audioService.playNewOrderSound();
  }
}
