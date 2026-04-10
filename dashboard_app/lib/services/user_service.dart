import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'users';

  // جلب جميع المستخدمين (مع إمكانية الفلترة حسب الفرع)
  static Future<List<UserModel>> getAllUsers({String? branch}) async {
    try {
      Query query = _db.collection(_collection);
      
      // فلترة حسب الفرع (المسؤول فقط يعرض الكل، العراق يعرض مستخدمي فرع العراق فقط)
      if (branch != null && branch.isNotEmpty && branch != 'المسؤول') {
        print('📍 UserService - فلترة المستخدمين للفرع: $branch');
        query = query.where('closestBranch', isEqualTo: branch);
      }
      
      final querySnapshot = await query.get();
      
      List<UserModel> users = [];
      for (var doc in querySnapshot.docs) {
        try {
          final user = UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
          users.add(user);
        } catch (e) {
          print('❌ خطأ في تحويل المستخدم ${doc.id}: $e');
          continue;
        }
      }
      
      // ترتيب محلياً حسب تاريخ الإنشاء
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('✅ UserService - تم جلب ${users.length} مستخدم للفرع: ${branch ?? "الكل"}');
      return users;
    } catch (e) {
      print('❌ UserService - خطأ في جلب المستخدمين: $e');
      return [];
    }
  }

  // جلب المستخدمين الجدد غير المراجعين (مع فلترة حسب الفرع)
  static Future<List<UserModel>> getNewUsers({String? branch}) async {
    try {
      Query query = _db.collection(_collection).where('isReviewed', isEqualTo: false);
      
      // فلترة حسب الفرع (المسؤول فقط يعرض الكل)
      if (branch != null && branch.isNotEmpty && branch != 'المسؤول') {
        query = query.where('closestBranch', isEqualTo: branch);
      }
      
      final querySnapshot = await query.get();
      
      // ترتيب النتائج محلياً
      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // ترتيب حسب تاريخ الإنشاء
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return users;
    } catch (e) {
      print('خطأ في جلب المستخدمين الجدد: $e');
      return [];
    }
  }

  // تحديث حالة المراجعة
  static Future<bool> markAsReviewed(String userId) async {
    try {
      await _db.collection(_collection).doc(userId).update({
        'isReviewed': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث حالة المراجعة: $e');
      return false;
    }
  }

  // تحديث حالة التفعيل/الحظر
  static Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      await _db.collection(_collection).doc(userId).update({
        'active': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث حالة المستخدم: $e');
      return false;
    }
  }

  // تحديث معلومات المستخدم
  static Future<bool> updateUser(String userId, UserModel user) async {
    try {
      await _db.collection(_collection).doc(userId).update({
        'name': user.name,
        'phone': user.phone,
        'city': user.city,
        'address': user.address,
        'near': user.near,
        'point': user.points,
        'active': user.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        if (user.shopLocation != null) 'shopLocation': user.shopLocation,
        if (user.profilePic != null) 'profilePic': user.profilePic,
        if (user.shopPic != null) 'shopPic': user.shopPic,
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث المستخدم: $e');
      return false;
    }
  }

  // حذف المستخدم
  static Future<bool> deleteUser(String userId) async {
    try {
      await _db.collection(_collection).doc(userId).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف المستخدم: $e');
      return false;
    }
  }

  // البحث في المستخدمين (مع فلترة حسب الفرع - جلب حسب الفرع ثم البحث محلياً)
  static Future<List<UserModel>> searchUsers(String searchQuery, {String? branch}) async {
    try {
      final users = await getAllUsers(branch: branch);
      if (searchQuery.isEmpty) return users;
      final query = searchQuery.toLowerCase();
      return users.where((u) => u.name.toLowerCase().contains(query)).toList();
    } catch (e) {
      print('خطأ في البحث: $e');
      return [];
    }
  }

  // جلب إحصائيات المستخدمين (مع فلترة حسب الفرع)
  static Future<Map<String, int>> getUserStats({String? branch}) async {
    try {
      Query allQuery = _db.collection(_collection);
      Query activeQuery = _db.collection(_collection).where('active', isEqualTo: true);
      Query newQuery = _db.collection(_collection).where('isReviewed', isEqualTo: false);
      
      // فلترة حسب الفرع (المسؤول فقط يعرض الكل)
      if (branch != null && branch.isNotEmpty && branch != 'المسؤول') {
        allQuery = allQuery.where('closestBranch', isEqualTo: branch);
        activeQuery = activeQuery.where('closestBranch', isEqualTo: branch);
        newQuery = newQuery.where('closestBranch', isEqualTo: branch);
      }
      
      final allUsers = await allQuery.get();
      final activeUsers = await activeQuery.get();
      final newUsers = await newQuery.get();

      return {
        'total': allUsers.docs.length,
        'active': activeUsers.docs.length,
        'new': newUsers.docs.length,
        'inactive': allUsers.docs.length - activeUsers.docs.length,
      };
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
      return {
        'total': 0,
        'active': 0,
        'new': 0,
        'inactive': 0,
      };
    }
  }
}
