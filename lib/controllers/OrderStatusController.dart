import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ecommerce/Services/RemoteServices.dart';
import 'package:ecommerce/models/Bill.dart';
import 'package:ecommerce/main.dart';

class OrderStatusController extends GetxController {
  var currentOrder = Rxn<Bill>();
  var isLoading = false.obs;
  Timer? _autoHideTimer;

  @override
  void onInit() {
    super.onInit();
    fetchCurrentOrder();
    // تحديث دوري كل 30 ثانية
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    Future.delayed(Duration(seconds: 30), () {
      if (isClosed == false) {
        fetchCurrentOrder();
        _startPeriodicUpdate(); // استمرار التحديث
      }
    });
  }

  // جلب أحدث طلب للمستخدم
  Future<void> fetchCurrentOrder() async {
    try {
      isLoading.value = true;
      final phone = sharedPreferences?.getString('phone');
      if (phone == null) return;

      final bills = await RemoteServices.fetchBills(phone);
      if (bills != null && bills.isNotEmpty) {
        // جلب أحدث طلب (الأول في القائمة)
        currentOrder.value = bills.first;
        
        // إذا كان الطلب "تم التوصيل"، ابدأ العد التنازلي للإخفاء التلقائي
        if (bills.first.orderstatus == 'تم التوصيل') {
          _startAutoHideTimer();
        }
      }
    } catch (e) {
      print('Error fetching current order: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // تحديث حالة الطلب
  Future<void> updateOrderStatus(String status) async {
    try {
      if (currentOrder.value != null) {
        currentOrder.value!.orderstatus = status;
        
        // إذا تغيرت الحالة إلى "تم التوصيل"، ابدأ العد التنازلي
        if (status == 'تم التوصيل') {
          _startAutoHideTimer();
        } else {
          // إذا تغيرت الحالة إلى شيء آخر، ألغِ المؤقت
          _autoHideTimer?.cancel();
        }
        
        update();
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  // الحصول على لون الحالة
  Color getStatusColor(String? status) {
    switch (status) {
      case 'قيد التحضير':
        return Colors.orange;
      case 'تم التحضير':
        return Colors.blue;
      case 'تم التوصيل':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // الحصول على أيقونة الحالة
  IconData getStatusIcon(String? status) {
    switch (status) {
      case 'قيد التحضير':
        return Icons.access_time;
      case 'تم التحضير':
        return Icons.check_circle_outline;
      case 'تم التوصيل':
        return Icons.delivery_dining;
      default:
        return Icons.info;
    }
  }

  // بدء العد التنازلي للإخفاء التلقائي بعد 10 دقائق
  void _startAutoHideTimer() {
    _autoHideTimer?.cancel(); // إلغاء المؤقت السابق إن وجد
    _autoHideTimer = Timer(Duration(minutes: 10), () {
      hideOrderStatus();
    });
  }

  // إخفاء شريط الحالة (عند انتهاء الطلب)
  void hideOrderStatus() {
    _autoHideTimer?.cancel(); // إلغاء المؤقت
    currentOrder.value = null;
  }

  @override
  void onClose() {
    _autoHideTimer?.cancel(); // إلغاء المؤقت عند إغلاق الكنترولر
    super.onClose();
  }
}
