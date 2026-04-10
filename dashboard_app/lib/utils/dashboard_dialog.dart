import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// إغلاق دايلوج مفتوح بـ [Get.dialog] بشكل موثوق (تفضيل overlay ثم Get.back).
void closeDashboardDialog({bool afterFrame = false}) {
  void pop() {
    final overlay = Get.overlayContext;
    if (overlay != null) {
      final nav = Navigator.of(overlay, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
        return;
      }
    }
    if (Get.isDialogOpen ?? false) {
      Get.back();
      return;
    }
    Get.back();
  }

  if (afterFrame) {
    WidgetsBinding.instance.addPostFrameCallback((_) => pop());
  } else {
    pop();
  }
}
