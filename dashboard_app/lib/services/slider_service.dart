import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/slider_model.dart';

class SliderService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'sliders';

  // جلب جميع العروض
  static Future<List<SliderModel>> getAllSliders() async {
    try {
      print('🔄 SliderService: بدء جلب العروض من Firebase...');
      
      final querySnapshot = await _db
          .collection(_collection)
          .get();

      print('📊 SliderService: تم جلب ${querySnapshot.docs.length} وثيقة');

      final sliders = querySnapshot.docs
          .map((doc) {
            try {
              return SliderModel.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              print('❌ خطأ في تحويل الوثيقة ${doc.id}: $e');
              return null;
            }
          })
          .where((slider) => slider != null)
          .cast<SliderModel>()
          .toList();
      
      // ترتيب محلياً حسب تاريخ الإنشاء
      sliders.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.now();
        final bDate = b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate); // ترتيب تنازلي
      });
      
      print('✅ SliderService: تم تحويل ${sliders.length} عرض بنجاح');
      return sliders;
    } catch (e) {
      print('❌ SliderService: خطأ في جلب العروض: $e');
      return [];
    }
  }

  // جلب عرض واحد
  static Future<SliderModel?> getSliderById(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (doc.exists) {
        return SliderModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('خطأ في جلب العرض: $e');
      return null;
    }
  }

  // إضافة عرض جديد
  static Future<bool> addSlider(SliderModel slider) async {
    try {
      final docRef = await _db.collection(_collection).add({
        'title': slider.title,
        'image': slider.image,
        'active': slider.active,
        'originalId': slider.originalId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('تم إضافة العرض بنجاح: ${docRef.id}');
      return true;
    } catch (e) {
      print('خطأ في إضافة العرض: $e');
      return false;
    }
  }

  // تحديث عرض موجود
  static Future<bool> updateSlider(String id, SliderModel slider) async {
    try {
      await _db.collection(_collection).doc(id).update({
        'title': slider.title,
        'image': slider.image,
        'active': slider.active,
        'originalId': slider.originalId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('تم تحديث العرض بنجاح: $id');
      return true;
    } catch (e) {
      print('خطأ في تحديث العرض: $e');
      return false;
    }
  }

  // حذف عرض
  static Future<bool> deleteSlider(String id) async {
    try {
      await _db.collection(_collection).doc(id).delete();
      print('تم حذف العرض بنجاح: $id');
      return true;
    } catch (e) {
      print('خطأ في حذف العرض: $e');
      return false;
    }
  }

  // تبديل حالة العرض (نشط/غير نشط)
  static Future<bool> toggleSliderStatus(String id, bool active) async {
    try {
      await _db.collection(_collection).doc(id).update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('تم تبديل حالة العرض: $id -> $active');
      return true;
    } catch (e) {
      print('خطأ في تبديل حالة العرض: $e');
      return false;
    }
  }

  // جلب العروض النشطة فقط
  static Future<List<SliderModel>> getActiveSliders() async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .where('active', isEqualTo: true)
          .get();

      final sliders = querySnapshot.docs
          .map((doc) => SliderModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // ترتيب محلياً حسب تاريخ الإنشاء
      sliders.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.now();
        final bDate = b.createdAt ?? DateTime.now();
        return bDate.compareTo(aDate); // ترتيب تنازلي
      });
      
      return sliders;
    } catch (e) {
      print('خطأ في جلب العروض النشطة: $e');
      return [];
    }
  }

  // البحث في العروض
  static Future<List<SliderModel>> searchSliders(String query) async {
    try {
      final querySnapshot = await _db
          .collection(_collection)
          .orderBy('title')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      return querySnapshot.docs
          .map((doc) => SliderModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('خطأ في البحث في العروض: $e');
      return [];
    }
  }
}
