import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'categories';

  // جلب جميع الفئات
  static Future<List<CategoryModel>> getAllCategories() async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .orderBy('originalId')
          .get();

      return querySnapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب الفئات: $e');
      return [];
    }
  }

  // جلب فئة واحدة بالمعرف
  static Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (doc.exists) {
        return CategoryModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب الفئة: $e');
      return null;
    }
  }

  // جلب فئة بالمعرف الأصلي
  static Future<CategoryModel?> getCategoryByOriginalId(int originalId) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('originalId', isEqualTo: originalId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return CategoryModel.fromFirestore(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('خطأ في جلب الفئة بالمعرف الأصلي: $e');
      return null;
    }
  }

  // تحديث فئة
  static Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث الفئة: $e');
      return false;
    }
  }

  // حذف فئة
  static Future<bool> deleteCategory(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف الفئة: $e');
      return false;
    }
  }

  // إضافة فئة جديدة
  static Future<String?> addCategory(CategoryModel category) async {
    try {
      final docRef = await _db.collection(_collection).add(category.toFirestore());
      return docRef.id;
    } catch (e) {
      print('خطأ في إضافة الفئة: $e');
      return null;
    }
  }

  // جلب إحصائيات الفئات
  static Future<Map<String, int>> getCategoryStats() async {
    try {
      final categories = await getAllCategories();
      return {
        'total': categories.length,
        'active': categories.where((c) => c.active).length,
        'inactive': categories.where((c) => !c.active).length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الفئات: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }
}
