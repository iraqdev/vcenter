import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // رفع صورة إلى Firebase Storage
  static Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      // إنشاء اسم فريد للصورة
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final ref = _storage.ref().child('$folder/$fileName');

      // رفع الصورة
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // الحصول على رابط الصورة
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('تم رفع الصورة بنجاح: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('خطأ في رفع الصورة: $e');
      return null;
    }
  }

  // حذف صورة من Firebase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // استخراج المسار من الرابط
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      print('تم حذف الصورة بنجاح: $imageUrl');
      return true;
    } catch (e) {
      print('خطأ في حذف الصورة: $e');
      return false;
    }
  }

  // رفع صورة منتج وحذف الصورة القديمة
  static Future<String?> uploadProductImage(File imageFile, String? oldImageUrl) async {
    try {
      // حذف الصورة القديمة إذا كانت موجودة
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteImage(oldImageUrl);
      }

      // رفع الصورة الجديدة
      return await uploadImage(imageFile, 'products');
    } catch (e) {
      print('خطأ في رفع صورة المنتج: $e');
      return null;
    }
  }

  // رفع عدة صور لمنتج واحد
  static Future<List<String>> uploadMultipleProductImages(List<File> imageFiles, List<String>? oldImageUrls) async {
    try {
      List<String> uploadedUrls = [];
      
      // حذف الصور القديمة إذا كانت موجودة
      if (oldImageUrls != null && oldImageUrls.isNotEmpty) {
        for (String oldUrl in oldImageUrls) {
          await deleteImage(oldUrl);
        }
      }

      // رفع الصور الجديدة
      for (File imageFile in imageFiles) {
        final url = await uploadImage(imageFile, 'products');
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      print('تم رفع ${uploadedUrls.length} صورة بنجاح');
      return uploadedUrls;
    } catch (e) {
      print('خطأ في رفع الصور المتعددة: $e');
      return [];
    }
  }

  // حذف عدة صور
  static Future<bool> deleteMultipleImages(List<String> imageUrls) async {
    try {
      bool allDeleted = true;
      for (String url in imageUrls) {
        final success = await deleteImage(url);
        if (!success) {
          allDeleted = false;
        }
      }
      return allDeleted;
    } catch (e) {
      print('خطأ في حذف الصور المتعددة: $e');
      return false;
    }
  }

  // التحقق من صحة رابط الصورة
  static bool isValidImageUrl(String url) {
    return url.isNotEmpty && 
           (url.startsWith('http://') || url.startsWith('https://')) &&
           (url.contains('.jpg') || url.contains('.jpeg') || 
            url.contains('.png') || url.contains('.gif') || url.contains('.webp'));
  }
}
