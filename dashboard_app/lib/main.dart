import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'dnz_notifications.dart';
import 'services/dnz_push_service.dart';
import 'views/dashboard_home_screen.dart';
import 'views/products_management_screen.dart';
import 'views/users_management_screen.dart';
import 'views/new_users_review_screen.dart';
import 'views/orders_management_screen.dart';
import 'views/notifications_management_screen.dart';
import 'views/sliders_management_screen.dart';
import 'views/categories_management_screen.dart';
import 'views/customer_requests_screen.dart';
import 'views/customer_orders_screen.dart';
import 'views/product_linking_screen.dart';
import 'views/payment_gateway_screen.dart';
import 'views/customer_prices_screen.dart';
import 'controllers/user_controller.dart';
import 'controllers/product_controller.dart';
import 'controllers/category_controller.dart';
import 'controllers/subcategory_controller.dart';
import 'controllers/order_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/branch_controller.dart';
import 'controllers/slider_controller.dart';
import 'controllers/customer_request_controller.dart';
import 'services/audio_service.dart';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

/// نفس قناة DNZ/Cloud Functions — مع صوت الداشبورد الحالي.
const AndroidNotificationChannel _dnzPushChannel = AndroidNotificationChannel(
  'vcenter_push_v3',
  'إشعارات الداشبورد',
  description: 'تنبيهات DNZ مع صوت',
  importance: Importance.max,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('vcenter_notify'),
  enableVibration: true,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تهيئة FCM للداشبورد
  await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  if (Platform.isAndroid) {
    final notificationStatus = await Permission.notification.status;
    if (!notificationStatus.isGranted) {
      await Permission.notification.request();
    }
  }
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  const initSettings = InitializationSettings(android: androidInit);
  await _localNotifications.initialize(initSettings);
  await _localNotifications
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_dnzPushChannel);

  await DnzPushService.ensureInitialized();
  DNZNotifications.instance.onMessage((msg) {
    final title = msg['title']?.toString() ?? 'إشعار جديد';
    final body = msg['body']?.toString() ?? '';
    AudioService().playNewOrderSound();
    Get.snackbar(
      title,
      body,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  });

  // FCM احتياط فقط إذا WebSocket DNZ غير متصل (بدون تكرار)
  FirebaseMessaging.onMessage.listen((message) {
    if (DNZNotifications.instance.isWebSocketConnected) {
      print('📱 FCM skipped (DNZ WebSocket connected)');
      return;
    }
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'إشعار جديد';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';
    AudioService().playNewOrderSound();
    Get.snackbar(
      title,
      body,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  });

  // تهيئة المتحكمات
  Get.put(BranchController()); // يجب أن يكون أول متحكم لأن OrderController يعتمد عليه
  Get.put(UserController());
  Get.put(CategoryController());
  Get.put(SubCategoryController());
  Get.put(ProductController());
  Get.put(NotificationController());
  Get.put(SliderController());
  Get.put(CustomerRequestController());
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
          GetPage(name: '/categories', page: () => CategoriesManagementScreen()),
          GetPage(name: '/new_users', page: () => NewUsersReviewScreen()),
          GetPage(name: '/customer_requests', page: () => CustomerRequestsScreen()),
          GetPage(name: '/customer_orders', page: () => CustomerOrdersScreen()),
          GetPage(name: '/product_linking', page: () => const ProductLinkingScreen()),
          GetPage(name: '/payment_gateway', page: () => PaymentGatewayScreen()),
          GetPage(name: '/customer_prices', page: () => const CustomerPricesScreen()),
        ],
    );
  }
}
