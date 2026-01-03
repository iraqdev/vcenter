import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _slidersFolder = 'sliders';

  // رفع صورة العرض إلى Firebase Storage
  static Future<String?> uploadSliderImage(File imageFile, String sliderId) async {
    try {
      print('🔄 بدء رفع صورة العرض: $sliderId');
      
      // إنشاء اسم الملف مع timestamp لتجنب التكرار
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final fileName = 'slider_${sliderId}_$timestamp$extension';
      
      // إنشاء مرجع للملف في Firebase Storage
      final ref = _storage.ref().child(_slidersFolder).child(fileName);
      
      // رفع الملف
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // الحصول على رابط التحميل
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ تم رفع صورة العرض بنجاح: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('❌ خطأ في رفع صورة العرض: $e');
      return null;
    }
  }

  // حذف صورة العرض من Firebase Storage
  static Future<bool> deleteSliderImage(String imageUrl) async {
    try {
      print('🔄 بدء حذف صورة العرض: $imageUrl');
      
      // استخراج اسم الملف من الرابط
      final ref = _storage.refFromURL(imageUrl);
      
      // حذف الملف
      await ref.delete();
      
      print('✅ تم حذف صورة العرض بنجاح');
      return true;
      
    } catch (e) {
      print('❌ خطأ في حذف صورة العرض: $e');
      return false;
    }
  }

  // التحقق من صحة رابط Firebase Storage
  static bool isValidFirebaseStorageUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') || 
           url.contains('storage.googleapis.com');
  }
}
