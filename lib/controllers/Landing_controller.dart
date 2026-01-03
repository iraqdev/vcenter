import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ecommerce/views/Login.dart';
import '../main.dart';

class Landing_controller extends GetxController {
  RxInt selectedIndex = 0.obs;
  var username = sharedPreferences?.getString('name') ?? '';
  var phone = sharedPreferences?.getString('phone') ?? '';
  var cartItems = 0;


  void onItemTapped(int index) {
    selectedIndex.value = index;
    update();
  }

  var pagesViewScaffoldKey = GlobalKey<ScaffoldState>();
  void openDrawer() {
    pagesViewScaffoldKey.currentState?.openDrawer();
    update();
  }

  void closeDrawer() {
    pagesViewScaffoldKey.currentState?.closeDrawer();
    update();
  }

  void logout() {
    sharedPreferences!.clear();
    //BoxCart.clear();
    Get.off(() => Login());
  }

  void setCount() {
    int count = BoxCart.length;
    cartItems = count;
    update();
  }
}
