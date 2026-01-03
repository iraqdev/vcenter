import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce/models/SubCategory.dart';
import 'package:ecommerce/models/Bill.dart';
import 'package:ecommerce/models/Category.dart';
import 'package:ecommerce/models/Product.dart';
import 'package:ecommerce/models/ProductsModel.dart';
import 'package:ecommerce/models/Sale.dart';
import 'package:ecommerce/models/SizeModel.dart';
import 'package:ecommerce/models/UserInfo.dart';
import '../models/Slider.dart';
import 'package:ecommerce/utils/image_utils.dart';

class RemoteServices {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _colUsers = 'users';
  static const String _colProducts = 'products';
  static const String _colCategories = 'categories';
  static const String _colSubCategories = 'subCategories';
  static const String _colSliders = 'sliders';
  static const String _colSales = 'sales';
  //Login
  static Future login(phone, password) async {
    try {
      final query = await _db
          .collection(_colUsers)
          .where('phone', isEqualTo: phone)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return '{"message":"No user found"}';
      }
      final data = query.docs.first.data();
      final response = {
        'message': 'Login Successfully',
        'phone': data['phone'],
        'user_id': data['originalId'] ?? data['id'] ?? 0,
        'near': data['near'] ?? '',
        'active': (data['active'] == true || data['active'] == 1) ? 1 : 0,
        'username': data['name'] ?? '',
      };
      return jsonEncode(response);
    } catch (e) {
      return '{"message":"An unexpected error occurred","Status_code":500}';
    }
  }

  static Future deleteAccount(name, phone) async {
    try {
      final query = await _db
          .collection(_colUsers)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return '{"message":"User not found"}';
      }
      await _db.collection(_colUsers).doc(query.docs.first.id).delete();
      return '{"message":"Deleted Successfully"}';
    } catch (e) {
      return '{"message":"An unexpected error occurred","Status_code":500}';
    }
  }

  //Register
  static Future register(phone, name, password, city, address, near, shopLocation, closestBranch) async {
    try {
      // تحقق من تكرار الهاتف
      final dup = await _db
          .collection(_colUsers)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (dup.docs.isNotEmpty) {
        return '{"message":"Phone number already in use"}';
      }
      final now = FieldValue.serverTimestamp();
      
      Map<String, dynamic> userData = {
        'phone': phone,
        'name': name,
        'password': password,
        'city': city,
        'address': address,
        'near': near,
        'closestBranch': closestBranch, // إضافة أقرب فرع
        'point': 0,
        'active': true,
        'createdAt': now,
        'updatedAt': now,
      };
      
      // إضافة موقع المحل إذا كان متوفراً
      if (shopLocation != null) {
        userData['shopLocation'] = {
          'lat': shopLocation.latitude,
          'lng': shopLocation.longitude,
        };
      }
      
      final doc = await _db.collection(_colUsers).add(userData);
      // حفظ originalId إذا لزم التطابق مع النماذج الرقمية
      await doc.update({'originalId': DateTime.now().millisecondsSinceEpoch});
      return '{"message":"Register Successfully"}';
    } catch (e) {
      return '{"message":"An unexpected error occurred","Status_code":500}';
    }
  }

  //Fetch Profile From Endpoint (userInfo)
  static Future<List<UserInfo>?> fetchProfile(phone) async {
    try {
      final query = await _db
          .collection(_colUsers)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return [];
      final data = query.docs.first.data();
      final jsonStr = jsonEncode([{
        'id': data['originalId'] ?? 0,
        'name': data['name'] ?? '',
        'phone': data['phone'] ?? '',
        'city': data['city'] ?? '',
        'address': data['address'] ?? '',
        'password': data['password'] ?? '',
        'point': data['point'] ?? 0,
        'active': (data['active'] == true || data['active'] == 1) ? 1 : 0,
      }]);
      return userInfoFromJson(jsonStr);
    } catch (e) {
      return null;
    }
  }

  //Fetch Sizes by Color
  static Future<List<SizeModel>?> fetchSize(id) async {
    // لا يوجد حجم في البيانات المقدمة، سنعيد قائمة فارغة مؤقتًا
    return [];
  }

  //Fetch Products From Endpoint (getProducts)
  static Future<List<Product>?> fetchProducts() async {
    try {
      print('🔍 RemoteServices - جلب المنتجات من Firestore...');
      final snap = await _db.collection(_colProducts).where('active', isEqualTo: true).get();
      final list = snap.docs.map((d) => d.data()).toList();
      
      print('📊 RemoteServices - تم جلب ${list.length} منتج');
      
      // طباعة تفاصيل الرسائل للمنتجات الأولى
      for (var i = 0; i < list.length && i < 3; i++) {
        final data = list[i];
        final branchMessages = data['branchMessages'] ?? {};
        print('📦 RemoteServices - منتج ${i + 1}: ${data['title']}');
        print('   - رسائل الفروع: $branchMessages');
      }
      
      final jsonStr = jsonEncode(list.map((data) => {
        'id': data['originalId'] ?? 0,
        'title': data['title'] ?? '',
        'price': data['price'] ?? 0,
        'description': data['description'] ?? '',
        'image': ImageUtils.getCorrectImageUrl(
          (data['image'] ?? '').toString(),
          'product',
          (data['originalId'] ?? 0) is int
              ? (data['originalId'] ?? 0)
              : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
        ),
        'category': data['category'] ?? 0,
        'branchMessages': data['branchMessages'] ?? {},
      }).toList());
      
      final products = productFromJson(jsonStr);
      print('✅ RemoteServices - تم تحويل ${products.length} منتج بنجاح');
      
      return products;
    } catch (e) {
      print('❌ RemoteServices - خطأ في جلب المنتجات: $e');
      return null;
    }
  }

  static Future<List<Product>?> filterProducts(String title) async {
    // بحث في العنوان والوصف
    try {
      final q = title.trim();
      if (q.isEmpty) return await fetchProducts();
      
      // جلب جميع المنتجات أولاً
      final snap = await _db.collection(_colProducts).get();
      final allProducts = snap.docs.map((d) => d.data()).toList();
      
      // تصفية المنتجات محلياً للبحث في العنوان والوصف
      final filteredProducts = allProducts.where((data) {
        final productTitle = (data['title'] ?? '').toString().toLowerCase();
        final productDescription = (data['description'] ?? '').toString().toLowerCase();
        final searchQuery = q.toLowerCase();
        
        // البحث في العنوان والوصف
        return productTitle.contains(searchQuery) || productDescription.contains(searchQuery);
      }).toList();
      
      final jsonStr = jsonEncode(filteredProducts.map((data) => {
        'id': data['originalId'] ?? 0,
        'title': data['title'] ?? '',
        'price': data['price'] ?? 0,
        'description': data['description'] ?? '',
        'image': ImageUtils.getCorrectImageUrl(
          (data['image'] ?? '').toString(),
          'product',
          (data['originalId'] ?? 0) is int
              ? (data['originalId'] ?? 0)
              : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
        ),
        'category': data['category'] ?? 0,
        'branchMessages': data['branchMessages'] ?? {},
      }).toList());
      return productFromJson(jsonStr);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Product>?> filterItems(String title) async {
    // ترميز النص للتعامل مع المسافات والأحرف الخاصة
    try {
      return await filterProducts(title);
    } catch (e) {
      return [];
    }
  }

  //Fetch Items filter From Endpoint (getProduct)
  static Future<List<Product>?> fetchProductsRecently(
    int page,
    int limit,
  ) async {
    try {
      final snap = await _db
          .collection(_colProducts)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final list = snap.docs.map((d) => d.data()).toList();
      final jsonStr = jsonEncode(list.map((data) => {
        'id': data['originalId'] ?? 0,
        'title': data['title'] ?? '',
        'price': data['price'] ?? 0,
        'description': data['description'] ?? '',
        'image': ImageUtils.getCorrectImageUrl(
          (data['image'] ?? '').toString(),
          'product',
          (data['originalId'] ?? 0) is int
              ? (data['originalId'] ?? 0)
              : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
        ),
        'category': data['category'] ?? 0,
        'branchMessages': data['branchMessages'] ?? {},
      }).toList());
      return productFromJson(jsonStr);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Product>?> fetchProductsLast(int page, int limit) async {
    return fetchProductsRecently(page, limit);
  }

  //add new bill To Endpoint (addBill)
  static Future<String> addBill(
    String name,
    String phone,
    String city,
    String address,
    int price,
    int delivery,
    List<Map<String, dynamic>> items,
    user_phone,
    nearpoint,
    note,
    near,
  ) async {
    try {
      final now = FieldValue.serverTimestamp();
      
      // تحديد الفرع الأقرب بناءً على near
      String closestBranch = _determineClosestBranch(near);
      print('📍 RemoteServices - تحديد الفرع الأقرب: $closestBranch من $near');
      
      final doc = await _db.collection('bills').add({
        'name': name,
        'phone': phone,
        'city': city,
        'address': address,
        'price': price,
        'delivery': delivery,
        'items': items,
        'user_phone': user_phone,
        'nearpoint': nearpoint,
        'note': note,
        'near': near,
        'closestBranch': closestBranch, // إضافة الفرع الأقرب
        'status': 0,
        'orderstatus': 'قيد التحضير', // حالة الطلب الافتراضية
        'createdAt': now,
        'updatedAt': now,
      });
      await doc.update({'originalId': DateTime.now().millisecondsSinceEpoch});
      return '{"message":"Bill Added"}';
    } catch (e) {
      return '{"message":"An unexpected error occurred","Status_code":500}';
    }
  }
  
  // تحديد الفرع الأقرب بناءً على near
  static String _determineClosestBranch(String near) {
    if (near.contains('الغزالية') || near.contains('غزالية')) {
      return 'الغزالية';
    } else if (near.contains('الزعفرانية') || near.contains('زعفرانية')) {
      return 'الزعفرانية';
    } else if (near.contains('الاعظمية') || near.contains('اعظمية') || near.contains('الأعظمية')) {
      return 'الاعظمية';
    } else {
      return 'العراق'; // الافتراضي
    }
  }

  //Fetch Bills By Id From Endpoint (getBills)
  static Future<List<Bill>?> fetchBills(phone) async {
    try {
      print('🔍 RemoteServices - جلب الطلبات لرقم: $phone');
      
      final snap = await _db
          .collection('bills')
          .where('user_phone', isEqualTo: phone)
          .orderBy('createdAt', descending: true)
          .get();
      
      print('📊 RemoteServices - عدد الطلبات المستلمة: ${snap.docs.length}');
      
      final list = snap.docs.map((d) => d.data()).toList();
      
      // طباعة تفاصيل كل طلب
      for (int i = 0; i < list.length; i++) {
        final data = list[i];
        print('📋 RemoteServices - الطلب ${i + 1}:');
        print('   - user_phone: ${data['user_phone']} (${data['user_phone'].runtimeType})');
        print('   - phone: ${data['phone']} (${data['phone'].runtimeType})');
        print('   - orderstatus: ${data['orderstatus']} (${data['orderstatus'].runtimeType})');
        print('   - price: ${data['price']} (${data['price'].runtimeType})');
        print('   - id: ${data['originalId']} (${data['originalId'].runtimeType})');
        print('   - status: ${data['status']} (${data['status'].runtimeType})');
      }
      
      // تحويل البيانات مع معالجة الأخطاء
      final convertedData = list.map((data) {
        try {
          return {
            'id': data['originalId'] ?? 0,
            'name': data['name'] ?? '',
            'phone': data['phone'] ?? '',
            'city': data['city'] ?? '',
            'address': data['address'] ?? '',
            'status': data['status'] ?? 0,
            'date': (data['createdAt'] is Timestamp)
                ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
                : (data['date'] ?? ''),
            'price': data['price'] ?? 0,
            'delivery': data['delivery'] ?? 0,
            'user_id': 0, // يمكن الاحتفاظ به للتوافق مع النماذج
            'nearpoint': data['nearpoint'],
            'note': data['note'],
            'orderstatus': data['orderstatus'] ?? 'جاري التجهيز',
            'items': data['items'] ?? [], // إضافة تفاصيل المنتجات
            'closestBranch': data['closestBranch'], // إضافة الفرع الأقرب
          };
        } catch (e) {
          print('❌ RemoteServices - خطأ في تحويل طلب: $e');
          print('   - البيانات: $data');
          return null;
        }
      }).where((item) => item != null).toList();
      
      print('✅ RemoteServices - تم تحويل ${convertedData.length} طلب إلى JSON');
      final jsonStr = jsonEncode(convertedData);
      return billFromJson(jsonStr);
    } catch (e) {
      print('❌ RemoteServices - خطأ في جلب الطلبات: $e');
      return null;
    }
  }

  //Fetch Bills By Id From Endpoint (getBills)
  static Future<List<Bill>?> fetchLatestBills(phone) async {
    return fetchBills(phone);
  }

  // حذف الطلبات الملغاة القديمة
  static Future<void> deleteCancelledOrder(int orderId) async {
    try {
      print('🗑️ RemoteServices - حذف طلب ملغي: $orderId');
      
      final query = await _db
          .collection('bills')
          .where('originalId', isEqualTo: orderId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
        print('✅ RemoteServices - تم حذف الطلب: $orderId');
      } else {
        print('❌ RemoteServices - لم يتم العثور على الطلب للحذف: $orderId');
      }
    } catch (e) {
      print('❌ RemoteServices - خطأ في حذف الطلب: $e');
    }
  }

  //
  static Future<List<Sale>?> getBill(id) async {
    try {
      final snap = await _db
          .collection(_colSales)
          .where('billId', isEqualTo: id)
          .get();
      final list = snap.docs.map((d) => d.data()).toList();
      final jsonStr = jsonEncode(list.map((data) => {
        'id': data['originalId'] ?? 0,
        'bill_id': data['billId'] ?? 0,
        'product_id': data['productId'] ?? 0,
        'quantity': data['quantity'] ?? 0,
        'price': data['price'] ?? 0,
      }).toList());
      return saleFromJson(jsonStr);
    } catch (e) {
      return null;
    }
  }

  //Fetch Item By Id From Endpoint (getProduct)
  static Future<ProductModel?> fetchProductone(id) async {
    try {
      final snap = await _db
          .collection(_colProducts)
          .where('originalId', isEqualTo: id)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      final jsonStr = jsonEncode({
        'id': data['originalId'] ?? 0,
        'title': data['title'] ?? '',
        'price': data['price'] ?? 0,
        'image': ImageUtils.getCorrectImageUrl(
          (data['image'] ?? '').toString(),
          'product',
          (data['originalId'] ?? 0) is int
              ? (data['originalId'] ?? 0)
              : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
        ),
        'description': data['description'] ?? '',
        'category': data['category'] ?? 0,
        'images': List<String>.from(
          (data['images'] ?? []).map((x) => ImageUtils.getCorrectImageUrl(
                x.toString(),
                'product',
                (data['originalId'] ?? 0) is int
                    ? (data['originalId'] ?? 0)
                    : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
              )),
        ),
        'branchMessages': data['branchMessages'] ?? {},
      });
      return productModelFromJson(jsonStr);
    } catch (e) {
      return null;
    }
  }

  //Fetch Items By Category From Endpoint (getProductByCategory)
  static Future<List<Product>?> fetchProductByCate(
    id,
    idCat,
    page,
    limit,
  ) async {
    try {
      final snap = await _db
          .collection(_colProducts)
          .where('category', isEqualTo: id)
          .where('subCategory', isEqualTo: idCat)
          .limit(limit ?? 50)
          .get();
      final list = snap.docs.map((d) => d.data()).toList();
      final jsonStr = jsonEncode(list.map((data) => {
        'id': data['originalId'] ?? 0,
        'title': data['title'] ?? '',
        'price': data['price'] ?? 0,
        'description': data['description'] ?? '',
        'image': ImageUtils.getCorrectImageUrl(
          (data['image'] ?? '').toString(),
          'product',
          (data['originalId'] ?? 0) is int
              ? (data['originalId'] ?? 0)
              : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
        ),
        'category': data['category'] ?? 0,
        'branchMessages': data['branchMessages'] ?? {},
      }).toList());
      return productFromJson(jsonStr);
    } catch (e) {
      return null;
    }
  }

  //Fetch Sliders From Endpoint (getSliders)
  static Future<List<SliderBar>?> fetchSliders() async {
    try {
      final snap = await _db.collection(_colSliders).get();
      final list = snap.docs.map((d) => d.data()).toList();
      final jsonStr = jsonEncode(list.map((data) => {
        'id': data['originalId'] ?? 0,
        'title': data['title'] ?? '',
        'image': ImageUtils.getCorrectImageUrl(
          (data['image'] ?? '').toString(),
          'slider',
          (data['originalId'] ?? 0) is int
              ? (data['originalId'] ?? 0)
              : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
        ),
      }).toList());
      return sliderFromJson(jsonStr);
    } catch (e) {
      return null;
    }
  }

  //Fetch Sliders From Endpoint (getCategories)
  static Future<List<CategoryModel>?> fetchCategories() async {
    try {
      final snap = await _db.collection(_colCategories).where('active', isEqualTo: true).get();
      final list = snap.docs.map((d) => d.data()).toList();
      final jsonStr = jsonEncode(list.map((data) => {
        'id': data['originalId'] ?? 0,
        'title': data['title'] ?? '',
        'image': ImageUtils.getCorrectImageUrl(
          (data['image'] ?? '').toString(),
          'category',
          (data['originalId'] ?? 0) is int
              ? (data['originalId'] ?? 0)
              : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
        ),
        'active': 1,
      }).toList());
      return categoryModelFromJson(jsonStr);
    } catch (e) {
      return null;
    }
  }

  static Future<List<SubCategory>?> fetchSubCategories(id) async {
    try {
      final snap = await _db
          .collection(_colSubCategories)
          .where('category', isEqualTo: id)
          .get();
      final list = snap.docs.map((d) => d.data()).toList();
      final jsonStr = jsonEncode(list.map((data) => {
        'id': data['originalId'] ?? 0,
        'title': data['title'] ?? '',
        'category': data['category'] ?? 0,
        'branchMessages': data['branchMessages'] ?? {},
      }).toList());
      return subCategoryFromJson(jsonStr);
    } catch (e) {
      return null;
    }
  }

  static Future<String> addOrder(
    name,
    phone,
    total,
    payment_type,
    payment_number,
    payment_name,
  ) async {
    try {
      final now = FieldValue.serverTimestamp();
      await _db.collection('orders').add({
        'name': name,
        'phone': phone,
        'total': total,
        'payment_type': payment_type,
        'payment_number': payment_number,
        'payment_name': payment_name,
        'createdAt': now,
        'updatedAt': now,
      });
      return '{"message":"Order Added"}';
    } catch (e) {
      return '{"message":"An unexpected error occurred","Status_code":500}';
    }
  }

  // تحديث حالة الطلب
  static Future<String> updateOrderStatus(String userPhone, String newStatus) async {
    try {
      final query = await _db
          .collection('bills')
          .where('user_phone', isEqualTo: userPhone)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (query.docs.isEmpty) {
        return '{"message":"No order found"}';
      }
      
      await query.docs.first.reference.update({
        'orderstatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return '{"message":"Order status updated successfully"}';
    } catch (e) {
      return '{"message":"An unexpected error occurred","Status_code":500}';
    }
  }

  static Future<List<Product>?> filterProductsByCategoryAndQuery(
    int categoryId,
    int subCategoryId,
    String query,
  ) async {
    try {
      final q = query.trim();
      if (q.isEmpty) {
        final snap = await _db
            .collection(_colProducts)
            .where('category', isEqualTo: categoryId)
            .where('subCategory', isEqualTo: subCategoryId)
            .limit(100)
            .get();
        final list = snap.docs.map((d) => d.data()).toList();
        final jsonStr = jsonEncode(list.map((data) => {
          'id': data['originalId'] ?? 0,
          'title': data['title'] ?? '',
          'price': data['price'] ?? 0,
          'description': data['description'] ?? '',
          'image': ImageUtils.getCorrectImageUrl(
            (data['image'] ?? '').toString(),
            'product',
            (data['originalId'] ?? 0) is int
                ? (data['originalId'] ?? 0)
                : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
          ),
          'category': data['category'] ?? 0,
        }).toList());
        return productFromJson(jsonStr);
      }

      final byTitle = await _db
          .collection(_colProducts)
          .orderBy('title')
          .startAt([q])
          .endAt([q + '\uf8ff'])
          .limit(200)
          .get();
      final list = byTitle.docs
          .map((d) => d.data())
          .where((data) => (data['category'] == categoryId) && (data['subCategory'] == subCategoryId))
          .toList();
      final jsonStr = jsonEncode(list.map((data) => {
        'id': data['originalId'] ?? 0,
        'title': data['title'] ?? '',
        'price': data['price'] ?? 0,
        'description': data['description'] ?? '',
        'image': ImageUtils.getCorrectImageUrl(
          (data['image'] ?? '').toString(),
          'product',
          (data['originalId'] ?? 0) is int
              ? (data['originalId'] ?? 0)
              : int.tryParse((data['originalId'] ?? '0').toString()) ?? 0,
        ),
        'category': data['category'] ?? 0,
        'branchMessages': data['branchMessages'] ?? {},
      }).toList());
      return productFromJson(jsonStr);
    } catch (e) {
      return null;
    }
  }
}
