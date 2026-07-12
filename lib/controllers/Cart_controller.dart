import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ecommerce/controllers/Billing_controller.dart';
import 'package:ecommerce/controllers/Landing_controller.dart';
import 'package:ecommerce/controllers/OrderStatusController.dart';
import 'package:ecommerce/controllers/OrdersController.dart';
import 'package:ecommerce/models/CartModel.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/Services/RemoteServices.dart';
import 'package:ecommerce/services/dnz_payment_service.dart';
import 'package:ecommerce/utils/delivery_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Cart_controller extends GetxController {
  var isAddedCart = false.obs;
  var isLoadingAdded = false.obs;
  var msgAdded = '';
  var total = 0;
  var isBlockAdded = false.obs;
  var isCreatingOnlinePayment = false;
  var isConfirmingOnlinePayment = false;
  Timer? _paymentPollTimer;
  bool _paymentPollBusy = false;

  void PlusAllData() {
    total = 0;
    for (var i = 0; i < BoxCart.length; ++i) {
      var item = BoxCart.getAt(i);
      if (item != null) {
        int price = item.price;
        int count = item.count;
        total += price * count;
      }
    }
    refreshCount();
    update();
  }

  void refreshCount() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Landing_controller landing_controller = Get.find();
      landing_controller.setCount();
    });
  }

  void updateCounterPlus(
      title, price, count, id, image, category, color, size) {
    var counter = count + 1;
    BoxCart.putAt(
        id,
        CartModel(
            price: price,
            title: title,
            count: counter,
            image: image,
            category: category,
            item: id,
            id: id,
            color: color,
            size: size));
    PlusAllData();
    update();
  }

  void updateCounterMin(title, price, count, id, image, category, color, size) {
    if (count > 1) {
      var counter = count - 1;
      BoxCart.putAt(
          id,
          CartModel(
              price: price,
              title: title,
              count: counter,
              image: image,
              category: category,
              item: id,
              id: id,
              color: color,
              size: size));
      PlusAllData();
      update();
    } else {}
  }

  void is_existsloading() {
    isAddedCart(false);
    isLoadingAdded(true);
    update();
  }

  void is_Bloackloading() {
    isBlockAdded(true);
    isAddedCart(false);
    isLoadingAdded(true);
    update();
  }

  void is_loading() {
    msgAdded = 'Loading';
    isAddedCart(true);
    isLoadingAdded(true);
    update();
  }

  void is_loadingDone() {
    msgAdded = 'Done';
    isLoadingAdded(false);
    update();
  }

  void Plus(title, price, count, id, image, category, color, size) {
    var counter = count + 1;
    BoxCart.putAt(
        id,
        CartModel(
            price: price,
            title: title,
            count: counter,
            image: image,
            category: category,
            item: id,
            id: id,
            color: color,
            size: size));
    PlusAllData();
    update();
  }

  void putDate(title, price, count, id, image, category, color, size) {
    is_loading();
    try {
      var totalCount = 0;
      for (var i = 0; i < BoxCart.length; ++i) {
        var item = BoxCart.getAt(i);
        if (item != null) {
          totalCount += item.count as int;
        }
      }
      print('Total : ${totalCount}');
      if (totalCount != 50) {
        if (!BoxCart.containsKey(id)) {
          BoxCart.put(
                  id,
                  CartModel(
                      price: price,
                      title: title,
                      count: count,
                      image: image,
                      category: category,
                      item: id,
                      id: id,
                      color: color,
                      size: size))
              .whenComplete(() {
            is_loadingDone();
            Cart_controller cart_controller = Get.put(Cart_controller());
            cart_controller.PlusAllData();
            Get.deleteAll();
            Get.toNamed('/landing');
          }).onError((error, stackTrace) {
            is_loadingDone();
            msgAdded = "Error";
            Get.deleteAll();
            Get.offAndToNamed('/landing');
          });
        } else {
          is_existsloading();
        }
      } else {
        is_Bloackloading();
        msgAdded = "Error";
      }

      isLoadingAdded(false);
      update();
    } catch (err) {
      print(err);
    }
  }

  void deleteData(index) {
    BoxCart.deleteAt(index);
    PlusAllData();
    update();
  }

  void deleteAll() {
    BoxCart.clear();
    PlusAllData();
    update();
  }

  String _productNameForPayment() {
    final names = <String>[];
    for (var i = 0; i < BoxCart.length; ++i) {
      final item = BoxCart.getAt(i);
      if (item == null) continue;
      names.add(item.title.toString());
      if (names.length >= 3) break;
    }
    final phone = sharedPreferences?.getString('phone') ?? '';
    final base = names.isEmpty ? 'طلب v center' : names.join(' + ');
    if (phone.isEmpty) return base;
    return '$base ($phone)';
  }

  /// نفس منطق رسوم التوصيل في إتمام الشراء.
  Future<int> _resolveDeliveryFeeForPayment() async {
    final userType = sharedPreferences?.getString('userType') ?? '';
    final city = sharedPreferences?.getString('city') ?? '';
    final address = sharedPreferences?.getString('address') ?? '';
    final branch = await RemoteServices.getUserClosestBranch();
    return deliveryFeeForUser(
      userType: userType,
      closestBranch: branch,
      city: city,
      address: address,
    );
  }

  /// دفع أونلاين عبر DNZ Gateway: مجموع المنتجات + التوصيل إن وُجد.
  /// يُنشأ الطلب فقط بعد نجاح الدفع (status = success).
  Future<void> payOnline() async {
    PlusAllData();
    if (BoxCart.isEmpty || total <= 0) {
      Get.snackbar(
        'عذرا',
        'السلة فارغة',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }
    if (sharedPreferences?.getString('phone') == null) {
      Get.snackbar(
        'عذرا',
        'يجب عليك تسجيل الدخول',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return;
    }
    if (isCreatingOnlinePayment) return;

    isCreatingOnlinePayment = true;
    update();

    try {
      final productsTotal = total;
      final delivery = await _resolveDeliveryFeeForPayment();
      final chargeAmount = productsTotal + delivery;
      final items = _cartItemsAsMaps();

      String? errorMsg;
      final created = await DnzPaymentService.createPaymentLink(
        productsTotal: chargeAmount,
        productName: _productNameForPayment(),
        description: 'دفع سلة v center',
        onError: (msg) => errorMsg = msg,
      );

      if (created == null) {
        Get.snackbar(
          'فشل الدفع',
          errorMsg ?? 'تعذر إنشاء رابط الدفع',
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }

      final uri = Uri.parse(created.paymentUrl);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        Get.snackbar(
          'خطأ',
          'تعذر فتح رابط الدفع',
          colorText: Colors.white,
          backgroundColor: Colors.red,
        );
        return;
      }

      Get.snackbar(
        'الدفع',
        'أكمل الدفع في الصفحة المفتوحة — سيتم تأكيد الطلب تلقائياً',
        colorText: Colors.white,
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 4),
      );

      _startAutoPaymentConfirmation(
        paymentId: created.paymentId,
        productsTotal: productsTotal,
        delivery: delivery,
        items: items,
      );
    } finally {
      isCreatingOnlinePayment = false;
      update();
    }
  }

  List<Map<String, dynamic>> _cartItemsAsMaps() {
    final list = <Map<String, dynamic>>[];
    for (int x = 0; x < BoxCart.length; x++) {
      final cartItem = BoxCart.getAt(x);
      if (cartItem == null) continue;
      list.add({
        'title': cartItem.title,
        'image': cartItem.image,
        'count': cartItem.count,
        'id': cartItem.id,
        'price': cartItem.price,
        'color': cartItem.color,
        'size': cartItem.size,
      });
    }
    return list;
  }

  void _stopPaymentPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = null;
    isConfirmingOnlinePayment = false;
    _paymentPollBusy = false;
  }

  /// فحص تلقائي في الخلفية بدون دايلوج — عند النجاح يُنشأ الطلب.
  void _startAutoPaymentConfirmation({
    required String paymentId,
    required int productsTotal,
    required int delivery,
    required List<Map<String, dynamic>> items,
  }) {
    _stopPaymentPolling();
    isConfirmingOnlinePayment = true;
    update();

    final startedAt = DateTime.now();
    const pollInterval = Duration(seconds: 3);
    const timeout = Duration(minutes: 10);

    Future<void> handleTick() async {
      if (!isConfirmingOnlinePayment || _paymentPollBusy) return;
      _paymentPollBusy = true;
      try {
        if (DateTime.now().difference(startedAt) > timeout) {
          _stopPaymentPolling();
          update();
          Get.snackbar(
            'انتهى الانتظار',
            'لم يتم تأكيد الدفع خلال الوقت المحدد. إن دفعت فعلاً تواصل مع الدعم.',
            colorText: Colors.white,
            backgroundColor: Colors.orange,
          );
          return;
        }

        final status = await DnzPaymentService.getPaymentStatus(paymentId);
        if (!isConfirmingOnlinePayment) return;

        if (DnzPaymentService.isFailedStatus(status)) {
          _stopPaymentPolling();
          update();
          Get.snackbar(
            'فشل الدفع',
            'عملية الدفع لم تنجح',
            colorText: Colors.white,
            backgroundColor: Colors.red,
          );
          return;
        }

        if (!DnzPaymentService.isSuccessStatus(status)) {
          return;
        }

        _stopPaymentPolling();
        final created = await _createOrderAfterSuccessfulPayment(
          paymentId: paymentId,
          productsTotal: productsTotal,
          delivery: delivery,
          items: items,
        );
        update();
        if (created) {
          Get.snackbar(
            'تم',
            'تم الدفع أونلاين وإنشاء الطلب بنجاح',
            colorText: Colors.white,
            backgroundColor: Colors.green,
          );
        }
      } finally {
        _paymentPollBusy = false;
      }
    }

    handleTick();
    _paymentPollTimer = Timer.periodic(pollInterval, (_) => handleTick());
  }

  Future<bool> _createOrderAfterSuccessfulPayment({
    required String paymentId,
    required int productsTotal,
    required int delivery,
    required List<Map<String, dynamic>> items,
  }) async {
    final name = sharedPreferences?.getString('name') ?? '';
    final phone = sharedPreferences?.getString('phone') ?? '';
    final near = sharedPreferences?.getString('near') ?? '';
    final nearpoint = sharedPreferences?.getString('nearpoint') ?? '';

    if (name.isEmpty || phone.isEmpty) {
      Get.snackbar(
        'خطأ',
        'بيانات المستخدم غير مكتملة',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return false;
    }

    final result = await RemoteServices.addBill(
      name,
      phone,
      '',
      '',
      productsTotal,
      delivery,
      items,
      phone,
      nearpoint,
      '',
      near,
      paymentMethod: 'دفع أونلاين',
      paymentId: paymentId,
    );

    if (!(result.contains('Bill Added') || result.contains('successfully'))) {
      Get.snackbar(
        'خطأ',
        'تم الدفع لكن تعذر إنشاء الطلب. تواصل مع الدعم.',
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
      return false;
    }

    try {
      final billing = Get.put(Billing_controller());
      final orderStatus = Get.put(OrderStatusController());
      final orders = Get.put(OrdersController());
      billing.fetchBills();
      orderStatus.fetchCurrentOrder();
      orders.fetchUserOrders();
    } catch (_) {}

    deleteAll();
    PlusAllData();
    return true;
  }

  @override
  void onInit() {
    PlusAllData();
    print('rady');
    // TODO: implement onInit
    super.onInit();
  }

  @override
  void onReady() {
    PlusAllData();
    print('rady');
    // TODO: implement onReady
    super.onReady();
  }

  @override
  void onClose() {
    _stopPaymentPolling();
    print('close');
    // TODO: implement onClose
    super.onClose();
  }
}
