import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>?> getProducts({String? branch}) async {
    try {
      print('🔍 FirebaseService - جلب المنتجات للفرع: ${branch ?? "الكل"}');
      final snap = await _db.collection('products').where('active', isEqualTo: true).get();
      var products = snap.docs.map((d) => d.data()).toList();
      // تصفية حسب الفرع: المنتجات القديمة بدون branch تظهر لجميع الفروع
      if (branch != null && branch.isNotEmpty && branch != 'المسؤول') {
        products = products.where((p) {
          final pBranch = p['branch'];
          return pBranch == branch || pBranch == null || pBranch.toString().isEmpty;
        }).toList();
      }
      print('✅ FirebaseService - تم جلب ${products.length} منتج');
      
      // طباعة تفاصيل المنتجات للتشخيص
      for (var product in products.take(3)) { // أول 3 منتجات فقط
        print('📦 منتج: ${product['title']}, active: ${product['active']}, originalId: ${product['originalId']}');
      }
      
      return products;
    } catch (e) {
      print('❌ خطأ في جلب المنتجات: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getSubCategories() async {
    try {
      print('🔍 FirebaseService - جلب الفئات الفرعية...');
      final snap = await _db.collection('subCategories').get();
      final subCategories = snap.docs.map((d) => d.data()).toList();
      print('✅ FirebaseService - تم جلب ${subCategories.length} فئة فرعية');
      
      // طباعة الفئات الفرعية للتشخيص
      for (var subCat in subCategories.take(10)) {
        print('📂 فئة فرعية: ${subCat['title']}, category: ${subCat['category']}, originalId: ${subCat['originalId']}');
      }
      
      return subCategories;
    } catch (e) {
      print('❌ خطأ في جلب الفئات الفرعية: $e');
      return null;
    }
  }
}


