import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/Services/RemoteServices.dart';
import 'package:ecommerce/models/Bill.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/utils/cancelled_order_utils.dart';

class OrdersController extends GetxController {
  var ordersList = <Bill>[].obs;
  var isLoading = false.obs;
  var isRefreshing = false.obs;
  var selectedOrder = Rxn<Bill>();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  Timer? _purgeTimer;
  bool _initialLoadDone = false;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    _purgeTimer?.cancel();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    await fetchUserOrders(showLoading: true);
    _listenToOrdersLive();
    // تنظيف الطلبات الملغية القديمة بشكل دوري دون تعطيل الواجهة
    _purgeTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      RemoteServices.purgeExpiredCancelledOrders();
    });
  }

  /// استماع مباشر لتغيّر الطلبات في Firestore (بدون انتظار سحب أو مؤقت).
  void _listenToOrdersLive() {
    final phone = sharedPreferences?.getString('phone');
    if (phone == null || phone.isEmpty) return;

    _ordersSub?.cancel();
    _ordersSub = FirebaseFirestore.instance
        .collection('bills')
        .where('user_phone', isEqualTo: phone)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snap) {
        if (isClosed) return;
        _applySnapshot(snap);
      },
      onError: (e) {
        print('❌ OrdersController live listen: $e');
        // في حال فشل الـ index/الاستماع نرجع للجلب اليدوي
        fetchUserOrders(showLoading: false);
      },
    );
  }

  void _applySnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    try {
      final now = DateTime.now();
      final filtered = <Bill>[];

      for (final doc in snap.docs) {
        final data = doc.data();
        final bill = _billFromFirestore(data);
        if (bill == null) continue;

        if (bill.orderstatus == 'ملغي') {
          DateTime? cancelledAt;
          if (bill.cancelledAt != null && bill.cancelledAt!.isNotEmpty) {
            cancelledAt = DateTime.tryParse(bill.cancelledAt!);
          }
          cancelledAt ??= DateTime.tryParse(bill.date);
          if (cancelledAt != null &&
              now.difference(cancelledAt) >= cancelledOrderRetention) {
            // حذف في الخلفية دون حجب الواجهة
            RemoteServices.deleteCancelledOrder(bill.id);
            continue;
          }
        }
        filtered.add(bill);
      }

      ordersList.value = filtered;
      _initialLoadDone = true;
      isLoading.value = false;
      isRefreshing.value = false;
      update();
    } catch (e) {
      print('❌ OrdersController _applySnapshot: $e');
    }
  }

  Bill? _billFromFirestore(Map<String, dynamic> data) {
    try {
      final map = {
        'id': data['originalId'] ?? 0,
        'name': data['name'] ?? '',
        'phone': data['phone'] ?? '',
        'city': data['city'] ?? '',
        'address': data['address'] ?? '',
        'status': data['status'] ?? 0,
        'date': (data['createdAt'] is Timestamp)
            ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
            : (data['date'] ?? ''),
        'price': data['price'] ?? 0,
        'delivery': data['delivery'] ?? 0,
        'user_id': 0,
        'nearpoint': data['nearpoint'],
        'note': data['note'],
        'orderstatus': data['orderstatus'] ?? 'جاري التجهيز',
        'items': data['items'] ?? [],
        'closestBranch': data['closestBranch'],
        'deliveryTime': data['deliveryTime'],
        'customerMessage': data['customerMessage']?.toString(),
        'deliveryDurationMinutes': data['deliveryDurationMinutes'],
        'deliveryDeadlineAt': (data['deliveryDeadlineAt'] is Timestamp)
            ? (data['deliveryDeadlineAt'] as Timestamp)
                .toDate()
                .toIso8601String()
            : data['deliveryDeadlineAt']?.toString(),
        'cancelledAt': (data['cancelledAt'] is Timestamp)
            ? (data['cancelledAt'] as Timestamp).toDate().toIso8601String()
            : null,
      };
      return Bill.fromJson(map);
    } catch (e) {
      print('❌ OrdersController _billFromFirestore: $e');
      return null;
    }
  }

  /// جلب الطلبات.
  /// [showLoading] = true فقط عند الفتح الأول حتى لا تختفي القائمة أثناء التحديث.
  Future<void> fetchUserOrders({bool showLoading = true}) async {
    try {
      final phone = sharedPreferences?.getString('phone');
      if (phone == null || phone.isEmpty) {
        print('❌ OrdersController - لا يوجد رقم هاتف');
        isLoading.value = false;
        return;
      }

      if (showLoading && !_initialLoadDone) {
        isLoading.value = true;
      } else {
        isRefreshing.value = true;
      }

      await RemoteServices.purgeExpiredCancelledOrders();
      final orders = await RemoteServices.fetchBills(phone);

      if (orders != null) {
        final filteredOrders = <Bill>[];
        final now = DateTime.now();

        for (final order in orders) {
          if (order.orderstatus == 'ملغي') {
            DateTime? cancelledAt;
            if (order.cancelledAt != null && order.cancelledAt!.isNotEmpty) {
              cancelledAt = DateTime.tryParse(order.cancelledAt!);
            }
            cancelledAt ??= DateTime.tryParse(order.date);
            if (cancelledAt != null &&
                now.difference(cancelledAt) >= cancelledOrderRetention) {
              await RemoteServices.deleteCancelledOrder(order.id);
              continue;
            }
          }
          filteredOrders.add(order);
        }

        ordersList.value = filteredOrders;
        _initialLoadDone = true;
        update();
      }
    } catch (e) {
      print('❌ OrdersController - خطأ في جلب الطلبات: $e');
      if (!_initialLoadDone) {
        Get.snackbar(
          'خطأ',
          'حدث خطأ في جلب الطلبات',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshOrders() async {
    await fetchUserOrders(showLoading: false);
  }

  void selectOrder(Bill order) {
    selectedOrder.value = order;
  }

  String _normalizeStatus(String? status) {
    final s = (status ?? '').trim();
    if (s == 'قيد التحضير') return 'جاري التجهيز';
    if (s == 'تم التوصيل') return 'تم الاستلام';
    return s;
  }

  Color getStatusColor(String? status) {
    switch (_normalizeStatus(status)) {
      case 'جاري التجهيز':
        return Colors.orange;
      case 'جاري التوصيل':
        return Colors.blue;
      case 'تم الاستلام':
        return Colors.green;
      case 'ملغي':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon(String? status) {
    switch (_normalizeStatus(status)) {
      case 'جاري التجهيز':
        return Icons.access_time;
      case 'جاري التوصيل':
        return Icons.delivery_dining;
      case 'تم الاستلام':
        return Icons.check_circle_outline;
      case 'ملغي':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'غير محدد';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  String formatTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'غير محدد';
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  double calculateTotal(Bill order) {
    return ((order.price) + (order.delivery)).toDouble();
  }

  int get pendingOrdersCount {
    return ordersList.where((order) {
      final s = _normalizeStatus(order.orderstatus);
      return s != 'تم الاستلام' && s != 'ملغي';
    }).length;
  }

  int get newOrdersCount {
    return ordersList
        .where((order) => _normalizeStatus(order.orderstatus) == 'جاري التجهيز')
        .length;
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final idInt = int.tryParse(orderId) ?? 0;
      final query = await FirebaseFirestore.instance
          .collection('bills')
          .where('originalId', isEqualTo: idInt)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'orderstatus': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final orderIndex =
            ordersList.indexWhere((order) => order.id.toString() == orderId);
        if (orderIndex != -1) {
          ordersList[orderIndex].orderstatus = newStatus;
          ordersList.refresh();
          update();
        }
      }
    } catch (e) {
      print('Error updating order status: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ في تحديث حالة الطلب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
