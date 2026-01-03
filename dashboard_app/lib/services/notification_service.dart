import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  static const String _collection = 'notifications';
  static const String _usersCollection = 'users';
  static const String _oneSignalApiUrl = 'https://onesignal.com/api/v1/notifications';
  static const String _oneSignalAppId = '806c1a69-cd15-41b1-8f83-d8a8b3f218f6';
  
  // مفتاح API الخاص بـ OneSignal
  static const String _oneSignalApiKey = 'os_v2_app_qbwbu2oncva3dd4d3culh4qy62rou2g3w22eaoeenroiwaczgl4zampl2gxby523iuhneet32xzrwjk42veukhx3wqjm4zulpu22kcy';

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // فحص حالة الاشتراك الفعلية في OneSignal
  static Future<bool> _checkPlayerSubscriptionStatus(String playerId) async {
    try {
      print('🔍 فحص حالة الاشتراك للمستخدم: $playerId');
      
      // استخدام OneSignal REST API للتحقق من حالة اللاعب
      final response = await http.get(
        Uri.parse('https://onesignal.com/api/v1/players/$playerId?app_id=$_oneSignalAppId'),
        headers: {
          'Authorization': 'Basic $_oneSignalApiKey',
          'Content-Type': 'application/json',
        },
      );

      print('📡 استجابة فحص الاشتراك: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final playerData = jsonDecode(response.body);
        final isSubscribed = playerData['invalid_identifier'] == false && 
                           playerData['invalid_identifier'] != true;
        
        print('📊 تفاصيل اللاعب:');
        print('   - invalid_identifier: ${playerData['invalid_identifier']}');
        print('   - isSubscribed: $isSubscribed');
        print('   - last_active: ${playerData['last_active']}');
        
        return isSubscribed;
      } else {
        print('❌ فشل في فحص حالة الاشتراك: ${response.statusCode}');
        print('   - Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ خطأ في فحص حالة الاشتراك: $e');
      return false;
    }
  }

  // إرسال إشعار لجميع المستخدمين (مع إمكانية التصفية حسب الفرع)
  static Future<Map<String, dynamic>> sendToAllUsers({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
    String? branch, // فلترة حسب الفرع
  }) async {
    try {
      // جلب جميع المستخدمين (مع الفلترة حسب الفرع إذا تم تحديده)
      Query query = _db.collection(_usersCollection);
      
      if (branch != null && branch.isNotEmpty) {
        print('📍 فلترة المستخدمين حسب الفرع: $branch');
        query = query.where('closestBranch', isEqualTo: branch);
      }
      
      final usersSnapshot = await query.get();

      print('🔍 عدد المستخدمين في Firebase: ${usersSnapshot.docs.length}');

      if (usersSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'لا يوجد مستخدمين في النظام',
          'sentCount': 0,
          'failedCount': 0,
        };
      }

      // طباعة تفاصيل كل مستخدم للمساعدة في التشخيص
      print('📋 تفاصيل المستخدمين:');
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        print('👤 المستخدم ${doc.id}:');
        print('   - playerId: ${userData['playerId'] ?? 'غير محدد'}');
        print('   - phone: ${userData['phone'] ?? 'غير محدد'}');
        print('   - name: ${userData['name'] ?? 'غير محدد'}');
        print('   - hasPlayerId: ${userData['playerId'] != null && userData['playerId'].toString().isNotEmpty}');
        print('---');
      }

      // استخراج player IDs من المستخدمين
      List<String> playerIds = [];
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        if (userData['playerId'] != null && userData['playerId'].toString().isNotEmpty) {
          playerIds.add(userData['playerId'].toString());
          print('✅ تم إضافة playerId: ${userData['playerId']}');
        } else {
          print('❌ المستخدم ${doc.id} لا يملك playerId صالح');
        }
      }

      print('📊 إجمالي playerIds صالحة: ${playerIds.length}');

      if (playerIds.isEmpty) {
        return {
          'success': false,
          'message': 'لا يوجد مستخدمين لديهم playerId (لم يسجلوا دخول بعد)',
          'sentCount': 0,
          'failedCount': 0,
        };
      }

      // إرسال الإشعار عبر OneSignal
      final response = await _sendOneSignalNotification(
        playerIds: playerIds,
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );

      // حفظ الإشعار في قاعدة البيانات
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: 'all',
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
        status: response['success'] ? 'sent' : 'failed',
        sentCount: response['success'] ? playerIds.length : 0,
        failedCount: response['success'] ? 0 : playerIds.length,
        errorMessage: response['success'] ? null : response['message'],
      );

      await _db.collection(_collection).doc(notification.id).set(notification.toFirestore());

      return {
        'success': response['success'],
        'message': response['message'],
        'sentCount': response['success'] ? playerIds.length : 0,
        'failedCount': response['success'] ? 0 : playerIds.length,
        'notificationId': notification.id,
      };
    } catch (e) {
      print('خطأ في إرسال الإشعار لجميع المستخدمين: $e');
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار: $e',
        'sentCount': 0,
        'failedCount': 0,
      };
    }
  }

  // إرسال إشعار لمستخدم محدد
  static Future<Map<String, dynamic>> sendToSpecificUser({
    required String phoneNumber,
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      // البحث عن المستخدم برقم الهاتف
      print('🔍 البحث عن المستخدم برقم الهاتف: $phoneNumber');
      final userSnapshot = await _db
          .collection(_usersCollection)
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      print('📊 عدد المستخدمين المطابقين: ${userSnapshot.docs.length}');
      
      if (userSnapshot.docs.isEmpty) {
        print('❌ المستخدم غير موجود');
        return {
          'success': false,
          'message': 'المستخدم غير موجود',
          'sentCount': 0,
          'failedCount': 1,
        };
      }

      final userData = userSnapshot.docs.first.data();
      print('👤 بيانات المستخدم: ${userData['name'] ?? 'غير محدد'}, Phone: ${userData['phone']}');
      final playerId = userData['playerId'];
      print('📱 Player ID: $playerId');

      if (playerId == null || playerId.toString().isEmpty) {
        print('❌ المستخدم لم يسجل دخول بعد (لا يوجد playerId)');
        return {
          'success': false,
          'message': 'المستخدم لم يسجل دخول بعد (لا يوجد playerId)',
          'sentCount': 0,
          'failedCount': 1,
        };
      }

      // فحص حالة الاشتراك الفعلية في OneSignal
      print('🔍 فحص حالة الاشتراك في OneSignal...');
      final subscriptionStatus = await _checkPlayerSubscriptionStatus(playerId.toString());
      print('📊 حالة الاشتراك: $subscriptionStatus');
      
      if (!subscriptionStatus) {
        print('❌ المستخدم غير مشترك في الإشعارات');
        return {
          'success': false,
          'message': 'المستخدم غير مشترك في الإشعارات (رفض الإشعارات أو لم يقبلها)',
          'sentCount': 0,
          'failedCount': 1,
        };
      }

      // إرسال الإشعار عبر OneSignal
      print('📤 إرسال الإشعار عبر OneSignal للمستخدم: ${userData['name']}');
      final response = await _sendOneSignalNotification(
        playerIds: [playerId.toString()],
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );

      print('📡 استجابة OneSignal: ${response['success']} - ${response['message']}');
      
      // تحديد حالة الإشعار بناءً على الاستجابة
      bool notificationSent = response['success'] ?? false;
      String notificationStatus = notificationSent ? 'sent' : 'failed';
      int sentCount = notificationSent ? 1 : 0;
      int failedCount = notificationSent ? 0 : 1;
      String? errorMessage = notificationSent ? null : response['message'];

      // حفظ الإشعار في قاعدة البيانات (مجموعة الإشعارات العامة)
      print('💾 إنشاء نموذج الإشعار...');
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: 'specific',
        targetPhone: phoneNumber,
        targetUserId: userSnapshot.docs.first.id,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
        status: notificationStatus,
        sentCount: sentCount,
        failedCount: failedCount,
        errorMessage: errorMessage,
      );

      print('💾 حفظ الإشعار في قاعدة البيانات: ${notification.id}');
      print('📋 بيانات الإشعار: ${notification.toFirestore()}');
      
      await _db.collection(_collection).doc(notification.id).set(notification.toFirestore());
      
      print('✅ تم حفظ الإشعار بنجاح في مجموعة: $_collection');

      // حفظ نسخة من الإشعار للمستخدم المحدد (لعرضها في زر الجرس)
      print('💾 حفظ نسخة للمستخدم في مجموعة notifications...');
      await _db.collection('notifications').add({
        'userId': userSnapshot.docs.first.id,
        'title': title,
        'body': message,
        'type': data?['type'] ?? 'general',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': data ?? {},
        'imageUrl': imageUrl,
        'actionUrl': actionUrl,
      });
      
      print('✅ تم حفظ نسخة للمستخدم بنجاح');

      return {
        'success': notificationSent,
        'message': notificationSent ? 'تم إرسال الإشعار بنجاح' : 'فشل في إرسال الإشعار: ${errorMessage ?? "خطأ غير معروف"}',
        'sentCount': sentCount,
        'failedCount': failedCount,
        'notificationId': notification.id,
      };
    } catch (e) {
      print('خطأ في إرسال الإشعار للمستخدم المحدد: $e');
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار: $e',
        'sentCount': 0,
        'failedCount': 1,
      };
    }
  }

  // إرسال إشعار ترويجي/عرض
  static Future<Map<String, dynamic>> sendPromotionalNotification({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
    String? targetPhone,
  }) async {
    if (targetPhone != null) {
      // إرسال لمستخدم محدد
      return await sendToSpecificUser(
        phoneNumber: targetPhone,
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );
    } else {
      // إرسال لجميع المستخدمين
      return await sendToAllUsers(
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        data: data,
      );
    }
  }

  // اختبار إرسال إشعار لمستخدم محدد
  static Future<Map<String, dynamic>> testSpecificUser({
    required String phoneNumber,
    required String title,
    required String message,
  }) async {
    try {
      // البحث عن المستخدم برقم الهاتف
      final usersSnapshot = await _db
          .collection(_usersCollection)
          .where('phone', isEqualTo: phoneNumber)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'لم يتم العثور على مستخدم برقم الهاتف: $phoneNumber',
        };
      }

      final userDoc = usersSnapshot.docs.first;
      final userData = userDoc.data();
      final playerId = userData['playerId'];

      if (playerId == null || playerId.toString().isEmpty) {
        return {
          'success': false,
          'message': 'المستخدم لا يملك playerId',
        };
      }

      print('🎯 اختبار مستخدم محدد:');
      print('   - Phone: $phoneNumber');
      print('   - Name: ${userData['name']}');
      print('   - Player ID: $playerId');

      // إرسال الإشعار للمستخدم المحدد
      final response = await _sendOneSignalNotification(
        playerIds: [playerId.toString()],
        title: title,
        message: message,
        data: {'type': 'specific_user_test'},
      );

      return response;
    } catch (e) {
      print('❌ خطأ في اختبار المستخدم المحدد: $e');
      return {
        'success': false,
        'message': 'خطأ في اختبار المستخدم المحدد: $e',
      };
    }
  }

  // اختبار OneSignal مباشرة
  static Future<Map<String, dynamic>> testOneSignalDirectly() async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_oneSignalApiKey',
      };

      final body = {
        'app_id': _oneSignalAppId,
        'included_segments': ['All'], // إرسال لجميع المستخدمين المسجلين في OneSignal
        'headings': {'en': 'اختبار إشعار', 'ar': 'اختبار إشعار'},
        'contents': {'en': 'هذا إشعار تجريبي من الداشبورد', 'ar': 'هذا إشعار تجريبي من الداشبورد'},
        'data': {'type': 'test', 'timestamp': DateTime.now().millisecondsSinceEpoch},
      };

      print('🚀 إرسال طلب OneSignal: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📡 استجابة OneSignal: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'تم إرسال الإشعار بنجاح',
          'oneSignalResponse': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'فشل في إرسال الإشعار: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('❌ خطأ في اختبار OneSignal: $e');
      return {
        'success': false,
        'message': 'خطأ في اختبار OneSignal: $e',
      };
    }
  }

  // إرسال إشعار مخصص لجميع المستخدمين
  static Future<Map<String, dynamic>> sendCustomNotificationToAll({
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_oneSignalApiKey',
      };

      final body = {
        'app_id': _oneSignalAppId,
        'included_segments': ['All'], // إرسال لجميع المستخدمين المسجلين في OneSignal
        'headings': {'en': title, 'ar': title},
        'contents': {'en': message, 'ar': message},
        'data': data ?? {},
      };

      // إضافة صورة إذا كانت متوفرة
      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['big_picture'] = imageUrl;
      }

      // إضافة رابط العمل إذا كان متوفراً
      if (actionUrl != null && actionUrl.isNotEmpty) {
        body['url'] = actionUrl;
      }

      print('🚀 إرسال إشعار مخصص لجميع المستخدمين:');
      print('   - Title: $title');
      print('   - Message: $message');
      print('   - Image URL: $imageUrl');
      print('   - Action URL: $actionUrl');
      print('   - Data: $data');

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📡 استجابة OneSignal: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'تم إرسال الإشعار بنجاح',
          'oneSignalResponse': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'فشل في إرسال الإشعار: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      print('❌ خطأ في إرسال الإشعار المخصص: $e');
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار المخصص: $e',
      };
    }
  }

  // إرسال إشعار مخصص لمستخدم محدد
  static Future<Map<String, dynamic>> sendCustomNotificationToSpecificUser({
    required String phoneNumber,
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('🔍 بدء البحث عن المستخدم برقم الهاتف: $phoneNumber');
      
      // البحث عن المستخدم برقم الهاتف مع طباعة تفاصيل أكثر
      final userSnapshot = await _db
          .collection(_usersCollection)
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      print('📊 نتائج البحث:');
      print('   - عدد النتائج: ${userSnapshot.docs.length}');
      print('   - رقم الهاتف المطلوب: $phoneNumber');

      // طباعة جميع المستخدمين للمقارنة
      final allUsersSnapshot = await _db
          .collection(_usersCollection)
          .limit(5)
          .get();
      
      print('👥 عينة من المستخدمين في قاعدة البيانات:');
      for (var doc in allUsersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        print('   - ID: ${doc.id}');
        print('   - Phone: ${userData['phone'] ?? 'غير محدد'}');
        print('   - Name: ${userData['name'] ?? 'غير محدد'}');
        print('   - Player ID: ${userData['playerId'] ?? 'غير محدد'}');
        print('   ---');
      }

      if (userSnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'المستخدم غير موجود برقم الهاتف: $phoneNumber',
          'sentCount': 0,
          'failedCount': 1,
        };
      }

      final userDoc = userSnapshot.docs.first;
      final userData = userDoc.data();
      final playerId = userData['playerId'];
      final userName = userData['name'] ?? 'غير محدد';
      final userPhone = userData['phone'];

      print('👤 تفاصيل المستخدم الموجود:');
      print('   - Document ID: ${userDoc.id}');
      print('   - الاسم: $userName');
      print('   - رقم الهاتف: $userPhone');
      print('   - Player ID: $playerId');
      print('   - نوع Player ID: ${playerId.runtimeType}');

      if (playerId == null || playerId.toString().isEmpty || playerId.toString() == 'null') {
        return {
          'success': false,
          'message': 'المستخدم لم يسجل دخول بعد (لا يوجد playerId صالح)',
          'sentCount': 0,
          'failedCount': 1,
        };
      }

      // إرسال الإشعار عبر OneSignal API مباشرة
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_oneSignalApiKey',
      };

      // محاولة الإرسال المباشر أولاً
      var body = {
        'app_id': _oneSignalAppId,
        'include_player_ids': [playerId.toString()],
        'headings': {'en': title, 'ar': title},
        'contents': {'en': message, 'ar': message},
        'data': data ?? {},
      };

      print('📤 محاولة الإرسال المباشر...');
      var response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📡 استجابة الإرسال المباشر: ${response.statusCode} - ${response.body}');

      // إذا فشل الإرسال المباشر، استخدم الإشعارات العامة مع رسالة مخصصة
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('errors') && responseData['errors'].isNotEmpty) {
          print('🔄 الإرسال المباشر فشل، استخدام الإشعارات العامة...');
          
          // إرسال إشعار عام مع رسالة مخصصة
          body = {
            'app_id': _oneSignalAppId,
            'included_segments': ['All'],
            'headings': {'en': 'إشعار مخصص لـ $userName', 'ar': 'إشعار مخصص لـ $userName'},
            'contents': {'en': 'عزيزي $userName ($phoneNumber): $message', 'ar': 'عزيزي $userName ($phoneNumber): $message'},
            'data': {
              ...data ?? {},
              'target_phone': phoneNumber,
              'target_name': userName,
            },
          };
          
          response = await http.post(
            Uri.parse(_oneSignalApiUrl),
            headers: headers,
            body: jsonEncode(body),
          );
          
          print('📡 استجابة الإشعار العام: ${response.statusCode} - ${response.body}');
        }
      }

      // إضافة صورة إذا كانت متوفرة
      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['big_picture'] = imageUrl;
      }

      // إضافة رابط العمل إذا كان متوفراً
      if (actionUrl != null && actionUrl.isNotEmpty) {
        body['url'] = actionUrl;
      }

      // حفظ نسخة من الإشعار للمستخدم المحدد (لعرضها في زر الجرس)
      print('💾 حفظ نسخة للمستخدم في مجموعة notifications...');
      try {
        await _db.collection('notifications').add({
          'userId': userDoc.id,
          'title': title,
          'body': message,
          'type': data?['type'] ?? 'general',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
          'data': data ?? {},
          'imageUrl': imageUrl,
          'actionUrl': actionUrl,
        });
        print('✅ تم حفظ نسخة للمستخدم بنجاح');
      } catch (e) {
        print('❌ خطأ في حفظ نسخة للمستخدم: $e');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'تم إرسال الإشعار بنجاح',
          'oneSignalResponse': responseData,
          'sentCount': 1,
          'failedCount': 0,
        };
      } else {
        return {
          'success': false,
          'message': 'فشل في إرسال الإشعار: ${response.statusCode} - ${response.body}',
          'sentCount': 0,
          'failedCount': 1,
        };
      }
    } catch (e) {
      print('❌ خطأ في إرسال الإشعار المخصص للمستخدم المحدد: $e');
      return {
        'success': false,
        'message': 'خطأ في إرسال الإشعار المخصص للمستخدم المحدد: $e',
        'sentCount': 0,
        'failedCount': 1,
      };
    }
  }

  // إرسال الإشعار عبر OneSignal API
  static Future<Map<String, dynamic>> _sendOneSignalNotification({
    required List<String> playerIds,
    required String title,
    required String message,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $_oneSignalApiKey',
      };

      final body = {
        'app_id': _oneSignalAppId,
        'include_player_ids': playerIds,
        'headings': {'en': title, 'ar': title},
        'contents': {'en': message, 'ar': message},
        'data': data ?? {},
      };

      // إضافة صورة إذا كانت متوفرة
      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['big_picture'] = imageUrl;
      }

      // إضافة رابط العمل إذا كان متوفراً
      if (actionUrl != null && actionUrl.isNotEmpty) {
        body['url'] = actionUrl;
      }

      print('🚀 إرسال طلب OneSignal:');
      print('   - App ID: $_oneSignalAppId');
      print('   - Player IDs: $playerIds');
      print('   - Title: $title');
      print('   - Message: $message');
      print('   - Body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(_oneSignalApiUrl),
        headers: headers,
        body: json.encode(body),
      );

      print('📡 استجابة OneSignal:');
      print('   - Status Code: ${response.statusCode}');
      print('   - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'تم إرسال الإشعار بنجاح',
          'oneSignalResponse': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'فشل في إرسال الإشعار: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'خطأ في الاتصال بـ OneSignal: $e',
      };
    }
  }

  // جلب جميع الإشعارات
  static Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب الإشعارات: $e');
      return [];
    }
  }

  // جلب إشعارات حسب النوع
  static Future<List<NotificationModel>> getNotificationsByType(String type) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب الإشعارات حسب النوع: $e');
      return [];
    }
  }

  // حذف إشعار
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await _db.collection(_collection).doc(notificationId).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف الإشعار: $e');
      return false;
    }
  }

  // جلب إحصائيات الإشعارات
  static Future<Map<String, int>> getNotificationStats() async {
    try {
      final allNotifications = await getAllNotifications();
      
      return {
        'total': allNotifications.length,
        'sent': allNotifications.where((n) => n.isSent).length,
        'failed': allNotifications.where((n) => n.isFailed).length,
        'scheduled': allNotifications.where((n) => n.isScheduled).length,
        'draft': allNotifications.where((n) => n.isDraft).length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الإشعارات: $e');
      return {
        'total': 0,
        'sent': 0,
        'failed': 0,
        'scheduled': 0,
        'draft': 0,
      };
    }
  }

  // البحث في الإشعارات
  static Future<List<NotificationModel>> searchNotifications(String query) async {
    try {
      final allNotifications = await getAllNotifications();
      
      return allNotifications.where((notification) {
        return notification.title.toLowerCase().contains(query.toLowerCase()) ||
               notification.message.toLowerCase().contains(query.toLowerCase()) ||
               notification.type.toLowerCase().contains(query.toLowerCase()) ||
               (notification.targetPhone?.contains(query) ?? false);
      }).toList();
    } catch (e) {
      print('خطأ في البحث في الإشعارات: $e');
      return [];
    }
  }

  // فحص جميع المستخدمين وطباعة تفاصيلهم
  static Future<Map<String, dynamic>> debugAllUsers() async {
    try {
      print('🔍 فحص جميع المستخدمين في قاعدة البيانات...');
      
      final usersSnapshot = await _db
          .collection(_usersCollection)
          .get();

      print('📊 إجمالي المستخدمين: ${usersSnapshot.docs.length}');
      print('👥 تفاصيل جميع المستخدمين:');
      
      int usersWithPlayerId = 0;
      int usersWithoutPlayerId = 0;
      
      for (var doc in usersSnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        final phone = userData['phone'] ?? 'غير محدد';
        final name = userData['name'] ?? 'غير محدد';
        final playerId = userData['playerId'];
        
        print('   📱 رقم الهاتف: $phone');
        print('   👤 الاسم: $name');
        print('   🆔 Player ID: $playerId');
        
        if (playerId != null && playerId.toString().isNotEmpty && playerId.toString() != 'null') {
          usersWithPlayerId++;
          print('   ✅ لديه Player ID صالح');
        } else {
          usersWithoutPlayerId++;
          print('   ❌ لا يوجد Player ID');
        }
        print('   ---');
      }
      
      print('📈 ملخص:');
      print('   - مستخدمين لديهم Player ID: $usersWithPlayerId');
      print('   - مستخدمين بدون Player ID: $usersWithoutPlayerId');
      
      return {
        'success': true,
        'message': 'تم فحص جميع المستخدمين',
        'totalUsers': usersSnapshot.docs.length,
        'usersWithPlayerId': usersWithPlayerId,
        'usersWithoutPlayerId': usersWithoutPlayerId,
      };
      
    } catch (e) {
      print('❌ خطأ في فحص المستخدمين: $e');
      return {
        'success': false,
        'message': 'خطأ في فحص المستخدمين: $e',
      };
    }
  }
}
