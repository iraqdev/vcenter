import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/main.dart';

class OrderRatingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'order_ratings';
  static const String _snoozePrefix = 'rating_snooze_until_';

  static String _docId(String phone, int orderOriginalId) =>
      '${phone.trim()}_$orderOriginalId';

  static String _snoozeKey(int orderOriginalId) =>
      '$_snoozePrefix$orderOriginalId';

  static bool isDeliveredStatus(String? status) {
    final s = (status ?? '').trim();
    return s == 'تم الاستلام' || s == 'تم التوصيل';
  }

  static Future<bool> hasRated(int orderOriginalId) async {
    try {
      final phone = sharedPreferences?.getString('phone');
      if (phone == null || phone.isEmpty) return false;
      final doc = await _db
          .collection(_collection)
          .doc(_docId(phone, orderOriginalId))
          .get();
      return doc.exists;
    } catch (e) {
      print('OrderRatingService.hasRated: $e');
      return false;
    }
  }

  /// هل ما زال المستخدم في فترة الإخفاء بعد الضغط على «لا»؟
  static Future<bool> isSnoozed(int orderOriginalId) async {
    try {
      final untilMs =
          sharedPreferences?.getInt(_snoozeKey(orderOriginalId)) ?? 0;
      if (untilMs <= 0) return false;
      return DateTime.now().millisecondsSinceEpoch < untilMs;
    } catch (_) {
      return false;
    }
  }

  static Future<void> snoozeFor({
    required int orderOriginalId,
    Duration duration = const Duration(minutes: 10),
  }) async {
    final until = DateTime.now().add(duration).millisecondsSinceEpoch;
    await sharedPreferences?.setInt(_snoozeKey(orderOriginalId), until);
  }

  static Future<void> clearSnooze(int orderOriginalId) async {
    await sharedPreferences?.remove(_snoozeKey(orderOriginalId));
  }

  static Future<bool> submitRating({
    required int orderOriginalId,
    required int rating,
    String? comment,
    String? userName,
    String? closestBranch,
    bool markDelivered = false,
  }) async {
    try {
      final phone = sharedPreferences?.getString('phone');
      if (phone == null || phone.isEmpty) return false;

      final docRef =
          _db.collection(_collection).doc(_docId(phone, orderOriginalId));
      final existing = await docRef.get();
      if (existing.exists) {
        if (markDelivered) {
          await _markBillDelivered(orderOriginalId, rating.clamp(1, 5));
        }
        await clearSnooze(orderOriginalId);
        return true;
      }

      await docRef.set({
        'orderOriginalId': orderOriginalId,
        'userPhone': phone,
        'userName': userName ?? '',
        'rating': rating.clamp(1, 5),
        'comment': (comment ?? '').trim(),
        'closestBranch': closestBranch ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final billUpdate = <String, dynamic>{
        'rated': true,
        'rating': rating.clamp(1, 5),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (markDelivered) {
        billUpdate['status'] = 2;
        billUpdate['orderstatus'] = 'تم الاستلام';
      }

      final billQuery = await _db
          .collection('bills')
          .where('originalId', isEqualTo: orderOriginalId)
          .limit(1)
          .get();
      if (billQuery.docs.isNotEmpty) {
        await billQuery.docs.first.reference.update(billUpdate);
      }

      await clearSnooze(orderOriginalId);
      return true;
    } catch (e) {
      print('OrderRatingService.submitRating: $e');
      return false;
    }
  }

  static Future<void> _markBillDelivered(int orderOriginalId, int rating) async {
    final billQuery = await _db
        .collection('bills')
        .where('originalId', isEqualTo: orderOriginalId)
        .limit(1)
        .get();
    if (billQuery.docs.isEmpty) return;
    await billQuery.docs.first.reference.update({
      'rated': true,
      'rating': rating.clamp(1, 5),
      'status': 2,
      'orderstatus': 'تم الاستلام',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
