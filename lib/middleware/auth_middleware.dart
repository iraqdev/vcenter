import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:ecommerce/main.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // التحقق من وجود بيانات تسجيل الدخول
    final phone = sharedPreferences?.getString('phone');
    final active = sharedPreferences?.getInt('active');
    final remember = sharedPreferences?.getBool('remember');
    
    print('🔍 فحص حالة تسجيل الدخول:');
    print('   - Phone: $phone');
    print('   - Active: $active');
    print('   - Remember: $remember');
    
    // إذا كان المستخدم مسجل دخول ومفعل
    if (phone != null && phone.isNotEmpty && 
        active != null && active == 1) {
      print('✅ المستخدم مسجل دخول - الانتقال للصفحة الرئيسية');
      return RouteSettings(name: '/landing');
    }
    
    // إذا لم يكن مسجل دخول أو غير مفعل
    print('❌ المستخدم غير مسجل دخول - البقاء في صفحة تسجيل الدخول');
    return null;
  }
}