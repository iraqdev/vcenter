import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ecommerce/main.dart';
import 'package:ecommerce/controllers/Landing_controller.dart';
import 'package:ecommerce/controllers/Home_controller.dart';
import 'package:ecommerce/controllers/Cart_controller.dart';
import 'package:ecommerce/controllers/OrdersController.dart';
import 'package:ecommerce/locale/Locale_controller.dart';
import 'package:ecommerce/views/Categories.dart';
import 'package:ecommerce/views/Home.dart';
import 'package:ecommerce/views/Profile.dart';
import 'package:ecommerce/views/Cart.dart';
import 'package:ecommerce/views/search_view.dart';
import 'package:ecommerce/views/OrdersScreen.dart';
import 'package:ecommerce/views/NotificationsScreen.dart';
import 'package:ecommerce/controllers/app_notification_controller.dart';
import 'package:ecommerce/controllers/ProfileController.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class Landing extends StatefulWidget {
  Landing({super.key});

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> with WidgetsBindingObserver {
  final Landing_controller controller = Get.put(Landing_controller());
  final locale_controller = Get.put(Locale_controller());

  // تهيئة Home_controller
  final Home_controller homeController = Get.put(Home_controller());
  
  // تهيئة OrdersController
  final OrdersController ordersController = Get.put(OrdersController());



  static final List<Widget> _pages = <Widget>[
    Home(),
    Categories(),
    CartPage(),
    OrdersScreen(),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // حفظ FCM token عند فتح التطبيق
    _saveFcmTokenOnAppOpen();
    // فحص حالة المستخدم الحالي (وحظره تلقائياً إذا تم من الداش)
    _checkUserStatus();
    // تهيئة متحكم الإشعارات
    Get.put(AppNotificationController());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // عند عودة التطبيق للمقدمة - فحص إذا تم حظر المستخدم من الداش
    if (state == AppLifecycleState.resumed) {
      _checkUserStatus();
    }
  }

  // دالة لحفظ FCM token عند فتح التطبيق
  Future<void> _saveFcmTokenOnAppOpen() async {
    try {
      // التحقق من وجود مستخدم مسجل دخول
      final phone = sharedPreferences?.getString('phone');
      if (phone == null || phone.isEmpty) return;
      
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;
      
      // البحث عن المستخدم في Firebase
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      
      if (usersSnapshot.docs.isNotEmpty) {
        final userDoc = usersSnapshot.docs.first;
        final userData = userDoc.data();
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .update({
          'fcmToken': fcmToken,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('تم حفظ FCM token عند فتح التطبيق: $phone');
      }
    } catch (e) {
      print('خطأ في حفظ FCM token عند فتح التطبيق: $e');
    }
  }

  // دالة لفحص حالة المستخدم الحالي (وتسجيل الخروج تلقائياً إذا تم حظره من الداش)
  Future<void> _checkUserStatus() async {
    try {
      print('🔍 فحص حالة المستخدم في Landing...');
      
      final phone = sharedPreferences?.getString('phone');
      if (phone == null || phone.isEmpty) {
        print('❌ لا يوجد مستخدم مسجل دخول في Landing');
        return;
      }
      
      print('📱 رقم الهاتف في Landing: $phone');
      
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .get();
      
      if (usersSnapshot.docs.isEmpty) {
        print('❌ لم يتم العثور على المستخدم في قاعدة البيانات في Landing');
        return;
      }
      
      final userData = usersSnapshot.docs.first.data();
      print('👤 بيانات المستخدم في Landing:');
      print('   - active: ${userData['active']}');
      print('   - closestBranch: ${userData['closestBranch']}');
      print('   - shopLocation: ${userData['shopLocation']}');
      
      // إذا تم حظر المستخدم من الداش - تسجيل الخروج وإبقاؤه يتصفح كزائر
      final isActive = userData['active'] == true || userData['active'] == 1;
      if (!isActive) {
        print('🚫 المستخدم محظور - تسجيل الخروج والتصفح كزائر');
        sharedPreferences?.clear();
        try { Get.find<ProfileController>().checkLoginStatus(); } catch (_) {}
        if (mounted) {
          setState(() {}); // تحديث الواجهة لعرض وضع الزائر
          Get.snackbar(
            'تم حظر حسابك',
            'تم تسجيل خروجك. يمكنك الاستمرار في التصفح كزائر',
            backgroundColor: Colors.orange[700],
            colorText: Colors.white,
            duration: Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
            margin: EdgeInsets.all(16),
          );
        }
        return;
      }
      
      if (userData['closestBranch'] == null || userData['closestBranch'].toString().isEmpty) {
        print('🚨 المستخدم في Landing لا يملك closestBranch - سيتم تحديد الموقع الآن');
        Future.delayed(Duration(seconds: 2), () {
          _detectLocationForUser(phone, usersSnapshot.docs.first.id, userData);
        });
      } else {
        print('✅ المستخدم في Landing لديه closestBranch: ${userData['closestBranch']}');
      }
      
    } catch (e) {
      print('❌ خطأ في فحص حالة المستخدم في Landing: $e');
    }
  }

  // دالة لتحديد موقع المستخدم (نسخة من main.dart)
  Future<void> _detectLocationForUser(String phone, String userId, Map<String, dynamic> userData) async {
    try {
      print('🌍 بدء تحديد الموقع للمستخدم في Landing: $phone');
      
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print('❌ تم رفض صلاحية الموقع في Landing');
        return;
      }
      
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ خدمات الموقع غير مفعلة في Landing');
        return;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );
      
      final userLocation = LatLng(position.latitude, position.longitude);
      
      // الحصول على المحافظة من بيانات المستخدم
      String? selectedGovernorate = userData['city'];
      final closestBranch = _findClosestBranch(userLocation, selectedGovernorate);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'shopLocation': {
          'lat': userLocation.latitude,
          'lng': userLocation.longitude,
        },
        'closestBranch': closestBranch,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ تم تحديد الموقع في Landing: $closestBranch');
      
    } catch (e) {
      print('❌ خطأ في تحديد الموقع في Landing: $e');
    }
  }

  // دالة لحساب أقرب فرع
  String _findClosestBranch(LatLng userLocation, String? selectedGovernorate) {
    // إذا لم تكن المحافظة بغداد، إرجاع "العراق"
    if (selectedGovernorate == null || selectedGovernorate != 'بغداد') {
      print('🏛️ المحافظة: $selectedGovernorate - سيتم حفظ "العراق"');
      return 'العراق';
    }
    
    // إذا كانت المحافظة بغداد، احسب أقرب فرع
    print('🏛️ المحافظة: $selectedGovernorate - سيتم حساب أقرب فرع في بغداد');
    
    final LatLng adhamya = LatLng(33.36961, 44.36373);
    final LatLng algazaly = LatLng(33.344803, 44.280755);
    final LatLng zafrania = LatLng(33.26082, 44.49870);
    
    Map<String, LatLng> branches = {
      'الاعظمية': adhamya,
      'الغزالية': algazaly,
      'الزعفرانية': zafrania,
    };

    String closestBranch = '';
    double minDistance = double.infinity;

    branches.forEach((branchName, branchLocation) {
      double distance = _calculateDistance(userLocation, branchLocation);
      print('المسافة إلى $branchName: ${(distance / 1000).toStringAsFixed(2)} كم');
      if (distance < minDistance) {
        minDistance = distance;
        closestBranch = branchName;
      }
    });

    print('أقرب فرع في بغداد: $closestBranch - المسافة: ${(minDistance / 1000).toStringAsFixed(2)} كم');
    return closestBranch;
  }

  // دالة لحساب المسافة
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;
    
    double lat1Rad = point1.latitude * (3.14159265359 / 180);
    double lat2Rad = point2.latitude * (3.14159265359 / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: controller.pagesViewScaffoldKey,
        appBar: AppBar(
          scrolledUnderElevation: 0.0,
          surfaceTintColor: Colors.deepPurple,
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leadingWidth: 56,
          leading: logo(),
          title: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => SearchView());
                  },
                  child: Container(
                    height: Get.height * 0.045,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: Get.width * 0.04),
                        Icon(
                          Icons.search,
                          color: Colors.deepPurple,
                          size: Get.width * 0.06,
                        ),
                        SizedBox(width: Get.width * 0.02),
                        Text(
                          '9'.tr,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: Get.width * 0.035,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // جرس الإشعارات
              _buildNotificationBell(),
            ],
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        bottomNavigationBar: Obx(
          () => BottomNavigationBar(
            currentIndex: controller.selectedIndex.value,
            type: BottomNavigationBarType.fixed,
            selectedItemColor:
                Colors.deepPurple, // Change to your desired color
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              controller.onItemTapped(index);
            },
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                label: '14'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.category_outlined),
                label: '15'.tr,
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.shopping_cart),
                    GetBuilder<Cart_controller>(
                      builder: (cartController) {
                        return BoxCart.length > 0
                            ? Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${BoxCart.length}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                            : SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                label: "السلة",
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Icon(Icons.shopping_bag_outlined),
                    GetBuilder<OrdersController>(
                      builder: (ordersController) {
                        try {
                          return ordersController.pendingOrdersCount > 0
                              ? Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${ordersController.pendingOrdersCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                              : SizedBox.shrink();
                        } catch (e) {
                          return SizedBox.shrink();
                        }
                      },
                    ),
                  ],
                ),
                label: 'طلباتي',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outlined),
                label: '17'.tr,
              ),
            ],
          ),
        ),
        body: GetBuilder<Landing_controller>(
          builder: (c) {
            return _pages.elementAt(c.selectedIndex.value);
          },
        ),
      ),
    );
  }

  SizedBox spaceH(double size) {
    return SizedBox(height: size);
  }

  SizedBox spaceW(double size) {
    return SizedBox(width: size);
  }


  Widget logo() {
    return Center(
      child: GestureDetector(
        onTap: () {
          final uri = Uri.tryParse('');
          if (uri != null) {}
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
            width: 40,
            height: 40,
          ),
        ),
      ),
    );
  }

  // بناء جرس الإشعارات
  Widget _buildNotificationBell() {
    return GetBuilder<AppNotificationController>(
      builder: (notificationController) {
        return GestureDetector(
          onTap: () {
            Get.to(() => NotificationsScreen());
          },
          child: Container(
            width: Get.height * 0.045,
            height: Get.height * 0.045,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.deepPurple,
                    size: Get.width * 0.06,
                  ),
                ),
                // عداد الإشعارات غير المقروءة
                Obx(() {
                  if (notificationController.unreadCount.value > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationController.unreadCount.value > 99 
                              ? '99+' 
                              : notificationController.unreadCount.value.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return SizedBox.shrink();
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
