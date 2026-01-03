import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ecommerce/Bindings/Billing_bindings.dart';
import 'package:ecommerce/Bindings/Checkout_bindings.dart';
import 'package:ecommerce/Bindings/ItemBilling_bindings.dart';
import 'package:ecommerce/Bindings/RecentlyProducts_bindings.dart';
import 'package:ecommerce/Bindings/Cart_bindings.dart';
import 'package:ecommerce/Bindings/Category_bindings.dart';
import 'package:ecommerce/Bindings/Home_bindings.dart';
import 'package:ecommerce/Bindings/Landing_bindings.dart';
import 'package:ecommerce/Bindings/Product_bindings.dart';
import 'package:ecommerce/Bindings/Products_bindings.dart';
import 'package:ecommerce/locale/Locale_controller.dart';
import 'package:ecommerce/locale/locale.dart';
import 'package:ecommerce/middleware/auth_middleware.dart';
import 'package:ecommerce/controllers/app_notification_controller.dart';
import 'package:ecommerce/models/CartModel.dart';
import 'package:ecommerce/models/FavoriteModel.dart';
import 'package:ecommerce/views/Billing.dart';
import 'package:ecommerce/views/Checkout.dart';
import 'package:ecommerce/views/Favorites.dart';
import 'package:ecommerce/views/Item_Billing.dart';
import 'package:ecommerce/views/RecentlyProducts.dart';
import 'package:ecommerce/views/Cart.dart';
import 'package:ecommerce/views/Categories.dart';
import 'package:ecommerce/views/Home.dart';
import 'package:ecommerce/views/Landing.dart';
import 'package:ecommerce/views/Login.dart';
import 'package:ecommerce/views/ProductPage.dart';
import 'package:ecommerce/views/Products.dart';
import 'package:ecommerce/views/RegisterView.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:hive/hive.dart';


SharedPreferences? sharedPreferences;
var formatter = NumberFormat("#,###");
late Box<CartModel> BoxCart;
late Box<FavoriteModel> BoxFavorite;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase والتطبيق في الخلفية
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCXPm9uDXkmXTuN1tIwh1Vgc2War5wU4b0',
        appId: '1:414036126974:ios:0901f66035f8cc516109af',
        messagingSenderId: '414036126974',
        projectId: 'v-center-5f74b',
        storageBucket: 'v-center-5f74b.firebasestorage.app',
      ),
    );
  } catch (e) {
    print('❌ Firebase initialization error: $e');
    // محاولة التهيئة بدون options (سيحاول العثور على GoogleService-Info.plist)
    await Firebase.initializeApp();
  }
  sharedPreferences = await SharedPreferences.getInstance();
  await Hive.initFlutter();
  Hive.registerAdapter(CartModelAdapter());
  Hive.registerAdapter(FavoriteModelAdapter());
  BoxCart = await Hive.openBox<CartModel>('BoxCart');
  BoxFavorite = await Hive.openBox<FavoriteModel>('Favorite');
  
  // تهيئة OneSignal مع معالجة أفضل للأخطاء
  try {
    OneSignal.initialize('806c1a69-cd15-41b1-8f83-d8a8b3f218f6');
    
    // طلب إذن الإشعارات
    OneSignal.Notifications.requestPermission(true);
    
    // إعداد OneSignal
    OneSignal.User.pushSubscription.optIn();
    
    print('✅ OneSignal initialized successfully');
  } catch (e) {
    print('❌ OneSignal initialization error: $e');
  }
  
  // تسجيل AppNotificationController
  Get.put(AppNotificationController());
  
  // إعداد معالج الإشعارات
  OneSignal.Notifications.addClickListener((event) {
    print('🔔 تم النقر على الإشعار: ${event.notification.title}');
    print('   - Body: ${event.notification.body}');
    print('   - Data: ${event.notification.additionalData}');
    // يمكنك إضافة منطق التنقل هنا
  });

  // إعداد معالج الإشعارات في الخلفية
  OneSignal.Notifications.addPermissionObserver((state) {
    print('🔔 تغيير إذن الإشعارات: $state');
  });

  // إعداد معالج الإشعارات المستلمة في الخلفية
  OneSignal.Notifications.addPermissionObserver((state) {
    print('🔔 حالة إذن الإشعارات: $state');
  });
  
  // إعداد معالج استلام الإشعارات
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print('📱 تم استلام إشعار في المقدمة:');
    print('   - Title: ${event.notification.title}');
    print('   - Body: ${event.notification.body}');
    print('   - Notification ID: ${event.notification.notificationId}');
    print('   - Data: ${event.notification.additionalData}');
    
    // عرض الإشعار حتى لو كان التطبيق مفتوح
    // لا حاجة لـ preventDefault() - دع OneSignal يعرض الإشعار تلقائياً
    
    // إضافة الإشعار للمتحكم
    try {
      // الانتظار قليلاً لضمان تهيئة المتحكم
      Future.delayed(Duration(milliseconds: 100), () {
        try {
          final notificationController = Get.find<AppNotificationController>();
          final newNotification = {
            'id': event.notification.notificationId,
            'title': event.notification.title ?? 'إشعار جديد',
            'body': event.notification.body ?? '',
            'timestamp': DateTime.now(),
            'isRead': false,
            'data': event.notification.additionalData ?? {},
          };
          notificationController.notifications.insert(0, newNotification);
          notificationController.unreadCount.value++;
          print('✅ تم إضافة الإشعار للمتحكم');
          print('   - عدد الإشعارات الآن: ${notificationController.notifications.length}');
          print('   - عدد غير المقروءة: ${notificationController.unreadCount.value}');
        } catch (e) {
          print('❌ خطأ في إضافة الإشعار للمتحكم: $e');
        }
      });
    } catch (e) {
      print('خطأ في معالجة الإشعار: $e');
    }
  });
  
  // حفظ Player ID للمستخدمين المسجلين مسبقاً (مع تأخير أكبر)
  Future.delayed(Duration(seconds: 5), () {
    _savePlayerIdForExistingUsers();
  });
  
  // OneSignal جاهز للعمل
  
  runApp(MaterialApp(
    home: VideoSplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class VideoSplashScreen extends StatefulWidget {
  @override
  _VideoSplashScreenState createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  VideoPlayerController? _controller;
  bool _isVideoFinished = false;
  bool _isVideoInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeEverything();
  }

  Future<void> _initializeEverything() async {
    // تهيئة الفيديو مباشرة
    await _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('Starting video initialization...');
      
      // تحميل الفيديو من مجلد assets
      _controller = VideoPlayerController.asset('assets/start2.mp4');
      
      // تهيئة الفيديو
      await _controller!.initialize();
      
      print('Video loaded successfully from assets');
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // إعداد الفيديو
        _controller!.setVolume(0.5); // تقليل الصوت لتجنب مشاكل الصوت
        _controller!.setPlaybackSpeed(1.0); // سرعة طبيعية
        
        // إضافة مستمع للفيديو
        _controller!.addListener(_videoListener);
        
        // تشغيل الفيديو
        _controller!.play();
        print('Video started playing');
        
        // timeout للانتقال التلقائي (أقصى 8 ثواني)
        Future.delayed(Duration(seconds: 8), () {
          if (mounted && !_isVideoFinished) {
            print('Video timeout - navigating to app');
            _navigateToApp();
          }
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      setState(() {
        _hasError = true;
      });
      // في حالة الخطأ، انتقل للتطبيق مباشرة بعد ثانية واحدة
      Future.delayed(Duration(seconds: 1), () {
        _navigateToApp();
      });
    }
  }

  void _videoListener() {
    if (_controller != null && 
        _controller!.value.position >= _controller!.value.duration &&
        _controller!.value.isInitialized) {
      _controller!.removeListener(_videoListener);
      _navigateToApp();
    }
  }

  void _navigateToApp() {
    if (mounted && !_isVideoFinished) {
      setState(() {
        _isVideoFinished = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideoFinished) {
      return MyApp();
    }

    return Container(
      color: Colors.black,
      child: _isVideoInitialized && _controller != null && _controller!.value.isInitialized
          ? Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          : _buildLoadingOrError(),
    );
  }

  Widget _buildLoadingOrError() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 60,
            ),
            SizedBox(height: 20),
            Text(
              'خطأ في تحميل الفيديو',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'جاري الانتقال للتطبيق...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Locale_controller locale_controller = Get.put(Locale_controller());
    
    return GetMaterialApp(
      translations: locale(),
      locale: locale_controller.inliaLang,
      title: '0'.tr,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Tajawal',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      initialBinding: Landing_bindings(),
      getPages: [
        GetPage(
          name: '/',
          page: () => Login(),
          binding: Landing_bindings(),
          middlewares: [AuthMiddleware()],
        ),
        GetPage(
            name: '/product',
            page: () => ProductPage(),
            binding: Product_bindings()),
        GetPage(
            name: '/landing',
            page: () => Landing(),
            binding: Landing_bindings()),
        GetPage(
            name: '/home', page: () => Home(), binding: Home_Bindings()),
        GetPage(
            name: '/bestProducts',
            page: () => RecentlyProducts(),
            binding: RecentlyProducts_bindings()),
        GetPage(
            name: '/cart',
            page: () => CartPage(),
            binding: Cart_bindings()),
        GetPage(
            name: '/categories',
            page: () => Categories(),
            binding: Category_bindings()),
        GetPage(
            name: '/products',
            page: () => Products(),
            binding: Products_bindings()),
        GetPage(
            name: '/checkout',
            page: () => Checkout(),
            binding: Checkout_bindings()),
        GetPage(
            name: '/favorites',
            page: () => Favorites(),
            binding: Checkout_bindings()),
        GetPage(
            name: '/billing',
            page: () => Billing(),
            binding: Billing_bindings()),
        GetPage(
            name: '/Item_Billing',
            page: () => Item_Billing(),
            binding: ItemBilling_bindings()),
        GetPage(
            name: '/register',
            page: () => RegisterView(),
            binding: Landing_bindings()),
      ],
    );
  }
}



// دالة لحفظ Player ID للمستخدمين المسجلين مسبقاً
Future<void> _savePlayerIdForExistingUsers() async {
  try {
    print('🔍 بدء فحص المستخدمين القدامى...');
    
    // التحقق من وجود مستخدم مسجل دخول
    final phone = sharedPreferences?.getString('phone');
    if (phone == null || phone.isEmpty) {
      print('❌ لا يوجد رقم هاتف في SharedPreferences');
      return;
    }
    
    print('📱 رقم الهاتف: $phone');
    
    // الحصول على Player ID من OneSignal
    final playerId = await OneSignal.User.getOnesignalId();
    if (playerId == null || playerId.isEmpty) {
      print('❌ لا يوجد Player ID من OneSignal');
      return;
    }
    
    print('🆔 Player ID: $playerId');
    
    // البحث عن المستخدم في Firebase
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    
    if (usersSnapshot.docs.isEmpty) {
      print('❌ لم يتم العثور على المستخدم في قاعدة البيانات');
      return;
    }
    
    final userDoc = usersSnapshot.docs.first;
    final userData = userDoc.data();
    
    print('👤 بيانات المستخدم: ${userData.keys.toList()}');
    print('🏢 closestBranch الحالي: ${userData['closestBranch']}');
    print('📍 shopLocation الحالي: ${userData['shopLocation']}');
    
    // التحقق من وجود playerId مسبقاً
    if (userData['playerId'] == null || userData['playerId'].toString().isEmpty) {
      // تحديث المستخدم بإضافة playerId
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .update({
        'playerId': playerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ تم حفظ Player ID للمستخدم المسجل مسبقاً: $phone');
    } else {
      print('ℹ️ Player ID موجود مسبقاً');
    }
    
    // التحقق من وجود closestBranch للمستخدمين القدامى
    final closestBranch = userData['closestBranch'];
    if (closestBranch == null || closestBranch.toString().isEmpty) {
      print('🚨 المستخدم $phone لا يملك closestBranch - سيتم تحديد الموقع تلقائياً');
      // تأخير قليل ثم تحديد الموقع
      Future.delayed(Duration(seconds: 3), () {
        _detectLocationForExistingUser(phone, userDoc.id, userData);
      });
    } else {
      print('✅ المستخدم $phone لديه closestBranch: $closestBranch');
    }
  } catch (e) {
    print('❌ خطأ في حفظ Player ID للمستخدم المسجل مسبقاً: $e');
  }
}

// دالة لتحديد موقع المستخدمين القدامى تلقائياً
Future<void> _detectLocationForExistingUser(String phone, String userId, Map<String, dynamic> userData) async {
  try {
    print('🌍 بدء تحديد الموقع للمستخدم القادم: $phone');
    
    // طلب صلاحية الموقع
    print('🔐 طلب صلاحية الموقع...');
    final permission = await Geolocator.requestPermission();
    print('📋 نتيجة الصلاحية: $permission');
    
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      print('❌ تم رفض صلاحية الموقع للمستخدم: $phone');
      return;
    }
    
    // التحقق من تفعيل خدمات الموقع
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('📍 خدمات الموقع مفعلة: $serviceEnabled');
    
    if (!serviceEnabled) {
      print('❌ خدمات الموقع غير مفعلة');
      return;
    }
    
    // الحصول على الموقع الحالي
    print('🎯 الحصول على الموقع الحالي...');
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );
    
    final userLocation = LatLng(position.latitude, position.longitude);
    print('📍 الموقع المحصل عليه: ${userLocation.latitude}, ${userLocation.longitude}');
    
    // حساب أقرب فرع
    print('🧮 حساب أقرب فرع...');
    
    // الحصول على المحافظة من بيانات المستخدم
    String? selectedGovernorate = userData['city'];
    final closestBranch = _findClosestBranchForExistingUser(userLocation, selectedGovernorate);
    print('🏢 أقرب فرع محسوب: $closestBranch');
    
    // تحديث بيانات المستخدم
    print('💾 تحديث قاعدة البيانات...');
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
    
    print('✅ تم تحديد الموقع وأقرب فرع للمستخدم $phone: $closestBranch');
    print('🎉 تم تحديث قاعدة البيانات بنجاح!');
    
  } catch (e) {
    print('❌ خطأ في تحديد موقع المستخدم القادم $phone: $e');
    print('🔍 تفاصيل الخطأ: ${e.toString()}');
  }
}

// دالة لحساب أقرب فرع للمستخدمين القدامى
String _findClosestBranchForExistingUser(LatLng userLocation, String? selectedGovernorate) {
  // إذا لم تكن المحافظة بغداد، إرجاع "العراق"
  if (selectedGovernorate == null || selectedGovernorate != 'بغداد') {
    print('🏛️ المحافظة: $selectedGovernorate - سيتم حفظ "العراق"');
    return 'العراق';
  }
  
  // إذا كانت المحافظة بغداد، احسب أقرب فرع
  print('🏛️ المحافظة: $selectedGovernorate - سيتم حساب أقرب فرع في بغداد');
  
  // إحداثيات الفروع
  final LatLng adhamya = LatLng(33.36961, 44.36373);    // الاعظمية
  final LatLng algazaly = LatLng(33.344803, 44.280755); // الغزالية
  final LatLng zafrania = LatLng(33.26082, 44.49870);   // الزعفرانية
  
  Map<String, LatLng> branches = {
    'الاعظمية': adhamya,
    'الغزالية': algazaly,
    'الزعفرانية': zafrania,
  };

  String closestBranch = '';
  double minDistance = double.infinity;

  branches.forEach((branchName, branchLocation) {
    double distance = _calculateDistanceBetweenPoints(userLocation, branchLocation);
    print('المسافة إلى $branchName: ${(distance / 1000).toStringAsFixed(2)} كم');
    
    if (distance < minDistance) {
      minDistance = distance;
      closestBranch = branchName;
    }
  });

  print('أقرب فرع في بغداد: $closestBranch - المسافة: ${(minDistance / 1000).toStringAsFixed(2)} كم');
  return closestBranch;
}

// دالة لحساب المسافة بين نقطتين
double _calculateDistanceBetweenPoints(LatLng point1, LatLng point2) {
  const double earthRadius = 6371000; // نصف قطر الأرض بالمتر
  
  double lat1Rad = point1.latitude * (3.14159265359 / 180);
  double lat2Rad = point2.latitude * (3.14159265359 / 180);
  double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
  double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

  double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
      cos(lat1Rad) * cos(lat2Rad) *
      sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
  double c = 2 * asin(sqrt(a));

  return earthRadius * c; // المسافة بالمتر
}

// دالة لفحص حالة المستخدم الحالي (للمطورين)
Future<void> checkCurrentUserStatus() async {
  try {
    print('🔍 فحص حالة المستخدم الحالي...');
    
    final phone = sharedPreferences?.getString('phone');
    if (phone == null || phone.isEmpty) {
      print('❌ لا يوجد مستخدم مسجل دخول');
      return;
    }
    
    print('📱 رقم الهاتف: $phone');
    
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();
    
    if (usersSnapshot.docs.isEmpty) {
      print('❌ لم يتم العثور على المستخدم في قاعدة البيانات');
      return;
    }
    
    final userData = usersSnapshot.docs.first.data();
    print('👤 بيانات المستخدم:');
    print('   - الاسم: ${userData['name']}');
    print('   - الهاتف: ${userData['phone']}');
    print('   - closestBranch: ${userData['closestBranch']}');
    print('   - shopLocation: ${userData['shopLocation']}');
    print('   - playerId: ${userData['playerId']}');
    print('   - createdAt: ${userData['createdAt']}');
    print('   - updatedAt: ${userData['updatedAt']}');
    
    if (userData['closestBranch'] == null || userData['closestBranch'].toString().isEmpty) {
      print('🚨 المستخدم لا يملك closestBranch - سيتم تحديد الموقع الآن');
      _detectLocationForExistingUser(phone, usersSnapshot.docs.first.id, userData);
    } else {
      print('✅ المستخدم لديه closestBranch: ${userData['closestBranch']}');
    }
    
  } catch (e) {
    print('❌ خطأ في فحص حالة المستخدم: $e');
  }
}

// دالة لاختبار OneSignal
// OneSignal جاهز للعمل - لا حاجة لاختبارات تجريبية

