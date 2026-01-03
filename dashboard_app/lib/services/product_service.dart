import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'products';

  // جلب جميع المنتجات
  static Future<List<ProductModel>> getAllProducts() async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب المنتجات: $e');
      return [];
    }
  }

  // جلب المنتجات حسب الفئة
  static Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('category', isEqualTo: categoryId)
          .where('active', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في جلب المنتجات حسب الفئة: $e');
      return [];
    }
  }

  // جلب منتج واحد
  static Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _db.collection(_collection).doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب المنتج: $e');
      return null;
    }
  }

  // إضافة منتج جديد
  static Future<bool> addProduct(ProductModel product) async {
    try {
      await _db.collection(_collection).doc(product.id).set(product.toFirestore());
      return true;
    } catch (e) {
      print('خطأ في إضافة المنتج: $e');
      return false;
    }
  }

  // تحديث منتج
  static Future<bool> updateProduct(ProductModel product) async {
    try {
      print('🔍 ProductService - بدء تحديث المنتج في Firestore:');
      print('   - ID: ${product.id}');
      print('   - العنوان: ${product.title}');
      print('   - الرسائل: ${product.branchMessages}');
      
      final firestoreData = product.toFirestore();
      print('📝 ProductService - بيانات Firestore: $firestoreData');
      
      await _db.collection(_collection).doc(product.id).update(firestoreData);
      
      print('✅ ProductService - تم تحديث المنتج بنجاح في Firestore');
      return true;
    } catch (e) {
      print('❌ ProductService - خطأ في تحديث المنتج: $e');
      return false;
    }
  }

  // حذف منتج
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _db.collection(_collection).doc(productId).delete();
      return true;
    } catch (e) {
      print('خطأ في حذف المنتج: $e');
      return false;
    }
  }

  // تحديث حالة المنتج
  static Future<bool> updateProductStatus(String productId, bool active) async {
    try {
      await _db.collection(_collection).doc(productId).update({
        'active': active,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('خطأ في تحديث حالة المنتج: $e');
      return false;
    }
  }

  // البحث في المنتجات
  static Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .where('active', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في البحث: $e');
      return [];
    }
  }

  // جلب الفئات المتاحة
  static Future<List<int>> getCategories() async {
    try {
      final querySnapshot = await _db.collection(_collection).get();
      final categories = <int>{};
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          final categoryId = data['category'] is String 
              ? int.tryParse(data['category']) 
              : data['category'];
          if (categoryId != null) {
            categories.add(categoryId);
          }
        }
      }
      
      return categories.toList()..sort();
    } catch (e) {
      print('خطأ في جلب الفئات: $e');
      return [];
    }
  }

  // إحصائيات المنتجات
  static Future<Map<String, int>> getProductStats() async {
    try {
      final querySnapshot = await _db.collection(_collection).get();
      
      int totalProducts = querySnapshot.docs.length;
      int activeProducts = 0;
      int inactiveProducts = 0;
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['active'] == true) {
          activeProducts++;
        } else {
          inactiveProducts++;
        }
      }
      
      return {
        'total': totalProducts,
        'active': activeProducts,
        'inactive': inactiveProducts,
      };
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
      return {
        'total': 0,
        'active': 0,
        'inactive': 0,
      };
    }
  }
}
