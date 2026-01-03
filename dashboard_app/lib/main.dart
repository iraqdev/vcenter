import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'views/dashboard_home_screen.dart';
import 'views/products_management_screen.dart';
import 'views/users_management_screen.dart';
import 'views/new_users_review_screen.dart';
import 'views/orders_management_screen.dart';
import 'views/notifications_management_screen.dart';
import 'views/sliders_management_screen.dart';
import 'controllers/user_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/subcategory_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/branch_controller.dart';
import 'controllers/slider_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تهيئة OneSignal
  OneSignal.initialize('806c1a69-cd15-41b1-8f83-d8a8b3f218f6');
  
  // طلب إذن الإشعارات
  OneSignal.Notifications.requestPermission(true);
  
  // إعداد OneSignal للداشبورد
  OneSignal.User.pushSubscription.optIn();
  
  // اختبار OneSignal في الداشبورد
  _testOneSignalDashboard();

  // تهيئة المتحكمات
  Get.put(BranchController()); // يجب أن يكون أول متحكم لأن OrderController يعتمد عليه
  Get.put(UserController());
  Get.put(CategoryController());
  Get.put(SubCategoryController());
  Get.put(ProductController());
  Get.put(NotificationController());
  Get.put(SliderController());
  Get.put(OrderController()); // بعد BranchController

  runApp(DashboardApp());
}

class DashboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VCenter Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Cairo',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.deepPurple),
          ),
        ),
      ),
      home: DashboardHomeScreen(),
        getPages: [
          GetPage(name: '/', page: () => DashboardHomeScreen()),
          GetPage(name: '/users', page: () => UsersManagementScreen()),
          GetPage(name: '/products', page: () => ProductsManagementScreen()),
          GetPage(name: '/orders', page: () => OrdersManagementScreen()),
          GetPage(name: '/notifications', page: () => NotificationsManagementScreen()),
          GetPage(name: '/sliders', page: () => SlidersManagementScreen()),
          GetPage(name: '/new_users', page: () => NewUsersReviewScreen()),
        ],
    );
  }
}

// دالة لاختبار OneSignal في الداشبورد
Future<void> _testOneSignalDashboard() async {
  try {
    // الحصول على Player ID
    final playerId = await OneSignal.User.getOnesignalId();
    print('Dashboard OneSignal Player ID: $playerId');
    
    // التحقق من حالة الإذن
    final permission = await OneSignal.Notifications.permission;
    print('Dashboard OneSignal Permission: $permission');
    
    // التحقق من حالة الاشتراك
    final subscribed = await OneSignal.User.pushSubscription.optedIn;
    print('Dashboard OneSignal Subscribed: $subscribed');
    
    if (playerId != null && playerId.isNotEmpty) {
      print('✅ Dashboard OneSignal جاهز للعمل!');
    } else {
      print('❌ Dashboard OneSignal غير جاهز');
    }
    
  } catch (e) {
    print('خطأ في اختبار Dashboard OneSignal: $e');
  }
}