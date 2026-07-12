import 'package:get/get.dart';
import 'package:ecommerce/Services/RemoteServices.dart';
import 'package:ecommerce/controllers/Billing_controller.dart';
import 'package:ecommerce/controllers/Cart_controller.dart';
import 'package:ecommerce/controllers/OrderStatusController.dart';
import 'package:ecommerce/controllers/OrdersController.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/utils/delivery_utils.dart';

class Checkout_controller extends GetxController {
  var isPay = false.obs;
  var isSubmittingOrder = false.obs;
  int price = 0;
  int delivery = 0;
  int profit = 0;
  int currentStep = 0;
  var user_phone;
  int total_user = 0;
  int total = 0;
  int fullTotal = 0;
  var name_agent;
  var near;
  var nearpoint;
  var isResolvingDelivery = true;

  int get grandTotal => price + delivery;

  @override
  void onInit() {
    price = Get.arguments[0]['total'];
    total_user = Get.arguments[0]['totalUser'];
    profit = total_user - price;
    user_phone = sharedPreferences?.getString('phone');
    name_agent = sharedPreferences!.getString('name')!;
    near = sharedPreferences!.getString('near') ?? '';
    nearpoint = sharedPreferences!.getString('nearpoint') ?? '';
    fullTotal = total_user;
    super.onInit();
    _resolveDeliveryFee();
  }

  Future<void> _resolveDeliveryFee() async {
    isResolvingDelivery = true;
    update();
    try {
      final userType = sharedPreferences?.getString('userType') ?? '';
      final city = sharedPreferences?.getString('city') ?? '';
      final address = sharedPreferences?.getString('address') ?? '';
      final branch = await RemoteServices.getUserClosestBranch();
      delivery = deliveryFeeForUser(
        userType: userType,
        closestBranch: branch,
        city: city,
        address: address,
      );
      fullTotal = total_user + delivery;
    } finally {
      isResolvingDelivery = false;
      update();
    }
  }

  void ContinueStap() {
    if (currentStep < 2) {
      currentStep += 1;
    } else {
      // Handle last step actions (e.g., submitting)
      // You can add your logic here
    }
    update();
  }

  Future<bool> addBill(phone, city, address, price, delivery, items, nearpoint,
      note, near) async {
    // منع إرسال نفس الطلب أكثر من مرة عند الضغط المتكرر
    if (isSubmittingOrder.value) {
      return false;
    }
    isSubmittingOrder(true);
    update();

    var list = <Map<String, dynamic>>[];
    for (int x = 0; x < BoxCart.length; x++) {
      var cartItem = BoxCart.getAt(x);
      if (cartItem != null) {
        // Convert cartItem to Map<String, dynamic> if needed
        var mappedItem = {
          'title': cartItem.title,
          'image': cartItem.image,
          'count': cartItem.count,
          'id': cartItem.id,
          'price': cartItem.price,
          'color': cartItem.color,
          'size': cartItem.size,
        };
        list.add(mappedItem);
      }
    }

    try {
      var result = await RemoteServices.addBill(name_agent, phone, city, address,
          price, delivery, list, user_phone, nearpoint, note, near);
      
      print('Result from addBill: $result'); // للتشخيص
      
      if (result.contains('successfully') || result.contains('Bill Added')) {
        isPay(true);
        Cart_controller c = Get.put(Cart_controller());
        Billing_controller cBilling = Get.put(Billing_controller());
        OrderStatusController orderStatusController = Get.put(OrderStatusController());
        OrdersController ordersController = Get.put(OrdersController());
        
        cBilling.fetchBills();
        orderStatusController.fetchCurrentOrder(); // تحديث حالة الطلب
        ordersController.fetchUserOrders(); // تحديث شاشة طلباتي فوراً
        c.deleteAll();
        c.PlusAllData();
        update();
        return true;
      } else {
        print('Error in addBill: $result'); // للتشخيص
        Get.snackbar('خطأ', 'حدث خطأ في إتمام الطلب: $result');
        return false;
      }
    } catch (e) {
      print('Exception in addBill: $e'); // للتشخيص
      Get.snackbar('خطأ', 'حدث خطأ في إتمام الطلب: $e');
      return false;
    } finally {
      isSubmittingOrder(false);
      update();
    }
  }

  void CancelStap() {
    if (currentStep > 0) {
      currentStep -= 1;
    } else {
      currentStep = 0;
    }
    update();
  }
}
