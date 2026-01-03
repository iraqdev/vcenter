import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subcategory_model.dart';

class SubCategoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'subCategories'; // نفس اسم المجموعة المستخدم في التطبيق الرئيسي

  // جلب جميع الفئات الفرعية
  static Future<List<SubCategoryModel>> getAllSubCategories() async {
    try {
      print('🔍 SubCategoryService - جلب الفئات الفرعية من مجموعة: $_collection');
      final querySnapshot = await _db
          .collection(_collection)
          .get();

      print('✅ SubCategoryService - تم جلب ${querySnapshot.docs.length} فئة فرعية');
      
      final subCategories = querySnapshot.docs
          .map((doc) => SubCategoryModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // عرض جميع الفئات الفرعية (حتى غير النشطة)
      print('📊 SubCategoryService - إجمالي الفئات الفرعية: ${subCategories.length}');
      
      // طباعة الفئات الفرعية للتشخيص
      for (var subCat in subCategories.take(5)) {
        print('📂 فئة فرعية: ${subCat.title}, category: ${subCat.category}, originalId: ${subCat.originalId}, active: ${subCat.active}');
      }
      
      return subCategories;
    } catch (e) {
      print('❌ خطأ في جلب الفئات الفرعية: $e');
      return [];
    }
  }

  // جلب الفئات الفرعية حسب الفئة الرئيسية
  static Future<List<SubCategoryModel>> getSubCategoriesByCategory(int categoryId) async {
    try {
      print('🔍 SubCategoryService - جلب الفئات الفرعية للفئة: $categoryId');
      
      // جرب أولاً بدون فلتر active
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await _db
            .collection(_collection)
            .where('category', isEqualTo: categoryId)
            .get();
        print('✅ SubCategoryService - تم جلب ${querySnapshot.docs.length} فئة فرعية للفئة $categoryId (بدون فلتر active)');
      } catch (e) {
        print('❌ خطأ في جلب الفئات الفرعية: $e');
        return [];
      }
      
      final subCategories = querySnapshot.docs
          .map((doc) => SubCategoryModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // عرض جميع الفئات الفرعية للفئة (حتى غير النشطة)
      print('📊 SubCategoryService - إجمالي الفئات الفرعية للفئة $categoryId: ${subCategories.length}');
      
      // طباعة الفئات الفرعية للتشخيص
      for (var subCat in subCategories) {
        print('📂 فئة فرعية: ${subCat.title}, category: ${subCat.category}, originalId: ${subCat.originalId}, active: ${subCat.active}');
      }
      
      return subCategories;
    } catch (e) {
      print('❌ خطأ في جلب الفئات الفرعية حسب الفئة: $e');
      return [];
    }
  }

  // جلب فئة فرعية واحدة بالمعرف
  static Future<SubCategoryModel?> getSubCategoryById(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (doc.exists) {
        return SubCategoryModel.fromFirestore(doc.data()! as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب الفئة الفرعية: $e');
      return null;
    }
  }

  // جلب فئة فرعية بالمعرف الأصلي
  static Future<SubCategoryModel?> getSubCategoryByOriginalId(int originalId) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('originalId', isEqualTo: originalId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return SubCategoryModel.fromFirestore(
          querySnapshot.docs.first.data(),
          querySnapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print('خطأ في جلب الفئة الفرعية بالمعرف الأصلي: $e');
      return null;
    }
  }

  // تحديث فئة فرعية
  static Future<bool> updateSubCategory(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection(_collection).doc(id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث الفئة الفرعية: $e');
      return false;
    }
  }

  // حذف فئة فرعية
  static Future<bool> deleteSubCategory(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف الفئة الفرعية: $e');
      return false;
    }
  }

  // إضافة فئة فرعية جديدة
  static Future<String?> addSubCategory(SubCategoryModel subCategory) async {
    try {
      final docRef = await _db.collection(_collection).add(subCategory.toFirestore());
      return docRef.id;
    } catch (e) {
      print('خطأ في إضافة الفئة الفرعية: $e');
      return null;
    }
  }

  // جلب إحصائيات الفئات الفرعية
  static Future<Map<String, int>> getSubCategoryStats() async {
    try {
      final subCategories = await getAllSubCategories();
      return {
        'total': subCategories.length,
        'active': subCategories.where((c) => c.active).length,
        'inactive': subCategories.where((c) => !c.active).length,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات الفئات الفرعية: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }
}
