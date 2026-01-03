import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/Services/RemoteServices.dart';
import 'package:ecommerce/models/Bill.dart';
import 'package:ecommerce/main.dart';

class OrdersController extends GetxController {
  var ordersList = <Bill>[].obs;
  var isLoading = false.obs;
  var selectedOrder = Rxn<Bill>();
  Timer? _periodicTimer;

  @override
  void onInit() {
    super.onInit();
    fetchUserOrders();
    // بدء التحديث التلقائي كل 30 ثانية
    _startPeriodicUpdate();
  }

  @override
  void onClose() {
    _periodicTimer?.cancel();
    super.onClose();
  }

  // بدء التحديث الدوري
  void _startPeriodicUpdate() {
    _periodicTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!isClosed) {
        fetchUserOrders();
      }
    });
  }

  // جلب جميع طلبات المستخدم
  Future<void> fetchUserOrders() async {
    try {
      isLoading.value = true;
      final phone = sharedPreferences?.getString('phone');
      print('🔍 OrdersController - رقم الهاتف: $phone');
      
      if (phone == null) {
        print('❌ OrdersController - لا يوجد رقم هاتف');
        return;
      }

      print('📞 OrdersController - جلب الطلبات لرقم: $phone');
      final orders = await RemoteServices.fetchBills(phone);
      
      if (orders != null) {
        print('✅ OrdersController - تم جلب ${orders.length} طلب');
        
        // تصفية الطلبات الملغاة القديمة (أكثر من 3 أيام)
        final filteredOrders = <Bill>[];
        final now = DateTime.now();
        
        for (final order in orders) {
          if (order.orderstatus == 'ملغي') {
            // تحقق من تاريخ الإلغاء
            try {
              final cancelledDate = DateTime.parse(order.date);
              final daysDifference = now.difference(cancelledDate).inDays;
              
              if (daysDifference >= 3) {
                print('🗑️ OrdersController - حذف طلب ملغي قديم: ${order.id} (${daysDifference} يوم)');
                // حذف الطلب من Firebase
                await RemoteServices.deleteCancelledOrder(order.id);
                continue; // لا تضيفه للقائمة
              }
            } catch (e) {
              print('⚠️ OrdersController - خطأ في تحليل تاريخ الطلب: $e');
            }
          }
          filteredOrders.add(order);
        }
        
        print('📊 OrdersController - الطلبات بعد التصفية: ${filteredOrders.length}');
        
        // طباعة تفاصيل الطلبات المحولة
        for (int i = 0; i < filteredOrders.length; i++) {
          final order = filteredOrders[i];
          print('📋 OrdersController - الطلب ${i + 1}:');
          print('   - ID: ${order.id}');
          print('   - Name: ${order.name}');
          print('   - Phone: ${order.phone}');
          print('   - Price: ${order.price}');
          print('   - Status: ${order.status}');
          print('   - OrderStatus: ${order.orderstatus}');
        }
        
        ordersList.value = filteredOrders;
        print('📊 OrdersController - الطلبات المعلقة: $pendingOrdersCount');
        update(); // تحديث الواجهة لتحديث العداد الأخضر
      } else {
        print('❌ OrdersController - لم يتم جلب أي طلبات');
      }
    } catch (e) {
      print('❌ OrdersController - خطأ في جلب الطلبات: $e');
      Get.snackbar(
        'خطأ',
        'حدث خطأ في جلب الطلبات',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // تحديث الطلبات
  Future<void> refreshOrders() async {
    await fetchUserOrders();
  }

  // تحديد طلب معين لعرض تفاصيله
  void selectOrder(Bill order) {
    selectedOrder.value = order;
  }

  // الحصول على لون حالة الطلب
  Color getStatusColor(String? status) {
    switch (status) {
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

  // الحصول على أيقونة حالة الطلب
  IconData getStatusIcon(String? status) {
    switch (status) {
      case 'جاري التجهيز':
        return Icons.access_time;
      case 'جاري التوصيل':
        return Icons.check_circle_outline;
      case 'تم الاستلام':
        return Icons.delivery_dining;
      case 'ملغي':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // تنسيق التاريخ
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'غير محدد';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  // تنسيق الوقت
  String formatTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'غير محدد';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  // حساب إجمالي الطلب
  double calculateTotal(Bill order) {
    return ((order.price ?? 0) + (order.delivery ?? 0)).toDouble();
  }

  // حساب عدد الطلبات غير المسلمة (غير "تم الاستلام" و "ملغي")
  int get pendingOrdersCount {
    return ordersList.where((order) => 
      order.orderstatus != 'تم الاستلام' && order.orderstatus != 'ملغي'
    ).length;
  }

  // حساب عدد الطلبات الجديدة (جاري التجهيز)
  int get newOrdersCount {
    return ordersList.where((order) => order.orderstatus == 'جاري التجهيز').length;
  }

  // تحديث حالة طلب معين
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // تحديث في Firebase
      final query = await FirebaseFirestore.instance
          .collection('bills')
          .where('id', isEqualTo: orderId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'orderstatus': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // تحديث القائمة المحلية
        final orderIndex = ordersList.indexWhere((order) => order.id == orderId);
        if (orderIndex != -1) {
          ordersList[orderIndex].orderstatus = newStatus;
          ordersList.refresh(); // تحديث الـ UI
          update(); // تحديث العداد الأخضر
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
