import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'bills';

  // جلب جميع الطلبات
  static Future<List<OrderModel>> getAllOrders({String? branch}) async {
    try {
      Query query = _db.collection(_collection);
      
      // فلترة حسب الفرع إذا تم تحديده
      if (branch != null && branch.isNotEmpty) {
        print('📍 OrderService - فلترة الطلبات للفرع: $branch');
        query = query.where('closestBranch', isEqualTo: branch);
      }
      
      // جلب البيانات بدون ترتيب مؤقتاً لتجنب مشكلة Index
      final querySnapshot = await query.get();

      List<OrderModel> orders = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final order = OrderModel.fromFirestore(data, doc.id);
          orders.add(order);
        } catch (e) {
          print('❌ خطأ في تحويل الطلب ${doc.id}: $e');
          continue;
        }
      }
      
      // ترتيب محلياً
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ OrderService - تم جلب ${orders.length} طلب للفرع: ${branch ?? "الكل"}');
      return orders;
    } catch (e) {
      print('❌ OrderService - خطأ في جلب الطلبات: $e');
      return [];
    }
  }

  // جلب الطلبات حسب الحالة
  static Future<List<OrderModel>> getOrdersByStatus(int status, {String? branch}) async {
    try {
      Query query = _db.collection(_collection).where('status', isEqualTo: status);
      
      // فلترة حسب الفرع إذا تم تحديده
      if (branch != null && branch.isNotEmpty) {
        print('📍 OrderService - فلترة الطلبات حسب الحالة $status للفرع: $branch');
        query = query.where('closestBranch', isEqualTo: branch);
      }
      
      // جلب البيانات بدون ترتيب مؤقتاً لتجنب مشكلة Index
      final querySnapshot = await query.get();

      List<OrderModel> orders = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final order = OrderModel.fromFirestore(data, doc.id);
          orders.add(order);
        } catch (e) {
          print('❌ خطأ في تحويل الطلب ${doc.id}: $e');
          continue;
        }
      }
      
      // ترتيب محلياً
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ OrderService - تم جلب ${orders.length} طلب بحالة $status للفرع: ${branch ?? "الكل"}');
      return orders;
    } catch (e) {
      print('❌ OrderService - خطأ في جلب الطلبات حسب الحالة: $e');
      return [];
    }
  }

  // جلب طلبات المستخدم
  static Future<List<OrderModel>> getUserOrders(String userPhone) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('phone', isEqualTo: userPhone)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب طلبات المستخدم: $e');
      return [];
    }
  }

  // جلب طلب واحد
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _db.collection(_collection).doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب الطلب: $e');
      return null;
    }
  }

  // تحديث حالة الطلب
  static Future<bool> updateOrderStatus(String orderId, int newStatus, String newOrderStatus, {String? deliveryTime}) async {
    try {
      print('OrderService: بدء تحديث حالة الطلب في Firebase');
      print('OrderService: معرف الطلب: $orderId');
      print('OrderService: الحالة الجديدة: $newStatus ($newOrderStatus)');
      
      // التحقق من وجود الطلب أولاً
      final docRef = _db.collection(_collection).doc(orderId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        print('OrderService: الطلب غير موجود: $orderId');
        return false;
      }
      
      print('OrderService: الطلب موجود، بدء التحديث...');
      
      // إعداد البيانات للتحديث
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'orderstatus': newOrderStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // إضافة وقت التوصيل إذا تم توفيره
      if (deliveryTime != null && deliveryTime.isNotEmpty) {
        updateData['deliveryTime'] = deliveryTime;
        print('OrderService: إضافة وقت التوصيل: $deliveryTime');
      }
      
      // تحديث الطلب
      await docRef.update(updateData);
      
      print('OrderService: تم تحديث حالة الطلب بنجاح: $orderId -> $newStatus ($newOrderStatus)');
      return true;
    } catch (e) {
      print('OrderService: خطأ في تحديث حالة الطلب: $e');
      print('OrderService: نوع الخطأ: ${e.runtimeType}');
      return false;
    }
  }

  // تحديث الطلب
  static Future<bool> updateOrder(String orderId, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(orderId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث الطلب: $e');
      return false;
    }
  }

  // حذف الطلب
  static Future<bool> deleteOrder(String orderId) async {
    try {
      await _db.collection(_collection).doc(orderId).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف الطلب: $e');
      return false;
    }
  }

  // إضافة طلب جديد
  static Future<String?> addOrder(OrderModel order) async {
    try {
      final docRef = await _db.collection(_collection).add(order.toFirestore());
      return docRef.id;
    } catch (e) {
      print('خطأ في إضافة الطلب: $e');
      return null;
    }
  }

  // جلب إحصائيات الطلبات
  static Future<Map<String, int>> getOrderStats() async {
    try {
      final allOrders = await getAllOrders();
      
      return {
        'total': allOrders.length,
        'preparing': allOrders.where((o) => o.isPreparing).length,
        'delivering': allOrders.where((o) => o.isDelivering).length,
        'delivered': allOrders.where((o) => o.isDelivered).length,
        'cancelled': allOrders.where((o) => o.isCancelled).length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الطلبات: $e');
      return {
        'total': 0,
        'preparing': 0,
        'delivering': 0,
        'delivered': 0,
        'cancelled': 0,
      };
    }
  }

  // جلب إحصائيات الطلبات لفترة محددة
  static Future<Map<String, dynamic>> getOrderStatsForPeriod(DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      final orders = querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc.data(), doc.id))
          .toList();

      double totalRevenue = 0;
      for (var order in orders) {
        if (order.isDelivered) {
          totalRevenue += order.price;
        }
      }

      return {
        'totalOrders': orders.length,
        'totalRevenue': totalRevenue,
        'preparing': orders.where((o) => o.isPreparing).length,
        'delivering': orders.where((o) => o.isDelivering).length,
        'delivered': orders.where((o) => o.isDelivered).length,
        'cancelled': orders.where((o) => o.isCancelled).length,
        'averageOrderValue': orders.isNotEmpty ? totalRevenue / orders.length : 0,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الطلبات للفترة: $e');
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'preparing': 0,
        'delivering': 0,
        'delivered': 0,
        'cancelled': 0,
        'averageOrderValue': 0.0,
      };
    }
  }

  // البحث في الطلبات
  static Future<List<OrderModel>> searchOrders(String query) async {
    try {
      final allOrders = await getAllOrders();
      
      return allOrders.where((order) {
        return order.name.toLowerCase().contains(query.toLowerCase()) ||
               order.userPhone.contains(query) ||
               order.id.toLowerCase().contains(query.toLowerCase()) ||
               order.orderstatus.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('خطأ في البحث في الطلبات: $e');
      return [];
    }
  }

  // جلب الطلبات قيد التجهيز
  static Future<List<OrderModel>> getPreparingOrders({String? branch}) async {
    return getOrdersByStatus(0, branch: branch);
  }

  // جلب الطلبات قيد التوصيل
  static Future<List<OrderModel>> getDeliveringOrders({String? branch}) async {
    return getOrdersByStatus(1, branch: branch);
  }

  // جلب الطلبات المكتملة
  static Future<List<OrderModel>> getDeliveredOrders({String? branch}) async {
    return getOrdersByStatus(2, branch: branch);
  }

  // جلب الطلبات الملغية
  static Future<List<OrderModel>> getCancelledOrders({String? branch}) async {
    return getOrdersByStatus(3, branch: branch);
  }
}
