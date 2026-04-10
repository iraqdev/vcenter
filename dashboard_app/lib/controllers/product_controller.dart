import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';
import 'category_controller.dart';
import 'branch_controller.dart';

class ProductController extends GetxController {
  // قائمة المنتجات
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> filteredProducts = <ProductModel>[].obs;
  
  // حالة التحميل
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  
  // البحث والفلترة
  final RxString searchQuery = ''.obs;
  final RxInt selectedCategory = 0.obs;
  final RxInt selectedSubCategory = 0.obs;
  final RxString sortBy = 'createdAt'.obs;
  final RxBool sortDescending = true.obs;
  
  // الإحصائيات
  final RxMap<String, int> stats = <String, int>{}.obs;
  
  // الفئات المتاحة
  final RxList<int> categories = <int>[].obs;
  
  // مرجع لكونترولر الفئات
  late CategoryController categoryController;

  @override
  void onInit() {
    super.onInit();
    categoryController = Get.find<CategoryController>();
    final branchController = Get.find<BranchController>();
    fetchProducts(branch: branchController.selectedBranch.value);
    fetchCategories();
    fetchStats();
    
    // الاستماع لتغيير الفرع
    branchController.selectedBranch.listen((branch) {
      print('🔄 ProductController - تم تغيير الفرع إلى: $branch');
      fetchProducts(branch: branch);
      fetchStats();
    });
  }

  // جلب جميع المنتجات (حسب الفرع المختار)
  Future<void> fetchProducts({String? branch}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final fetchedProducts = await ProductService.getAllProducts(branch: branch);
      products.value = fetchedProducts;
      filteredProducts.value = fetchedProducts;
      
    } catch (e) {
      errorMessage.value = 'خطأ في جلب المنتجات: $e';
      print('خطأ في جلب المنتجات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // جلب الفئات
  Future<void> fetchCategories() async {
    try {
      // لا نحتاج لجلب الفئات هنا لأن CategoryController يتولى ذلك
      // categories.value = fetchedCategories;
    } catch (e) {
      print('خطأ في جلب الفئات: $e');
    }
  }

  // جلب الإحصائيات (حسب الفرع المختار)
  Future<void> fetchStats() async {
    try {
      final branchController = Get.find<BranchController>();
      final branch = branchController.selectedBranch.value;
      final fetchedStats = await ProductService.getProductStats(branch: branch);
      stats.value = fetchedStats;
    } catch (e) {
      print('خطأ في جلب الإحصائيات: $e');
    }
  }

  // البحث في المنتجات
  void searchProducts(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  // فلترة حسب الفئة
  void filterByCategory(int category) {
    selectedCategory.value = category;
    // عند تغيير الفئة الرئيسية نعيد تعيين الفئة الفرعية
    selectedSubCategory.value = 0;
    _applyFilters();
  }

  // فلترة حسب الفئة الفرعية
  void filterBySubCategory(int subCategory) {
    selectedSubCategory.value = subCategory;
    _applyFilters();
  }

  // ترتيب المنتجات
  void sortProducts(String field, {bool descending = true}) {
    sortBy.value = field;
    sortDescending.value = descending;
    _applyFilters();
  }

  // تطبيق الفلاتر
  void _applyFilters() {
    List<ProductModel> filtered = List.from(products);
    
    // فلترة حسب البحث
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((product) =>
        product.title.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        product.description.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        product.category.toString().contains(searchQuery.value)
      ).toList();
    }
    
    // فلترة حسب الفئة
    if (selectedCategory.value != 0) {
      filtered = filtered.where((product) =>
        product.category == selectedCategory.value
      ).toList();
    }

    // فلترة حسب الفئة الفرعية
    if (selectedSubCategory.value != 0) {
      filtered = filtered.where((product) =>
        product.subCategory == selectedSubCategory.value
      ).toList();
    }
    
    // ترتيب المنتجات
    filtered.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy.value) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'createdAt':
        default:
          comparison = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
          break;
      }
      
      return sortDescending.value ? -comparison : comparison;
    });
    
    filteredProducts.value = filtered;
  }

  // إضافة منتج جديد
  Future<bool> addProduct(ProductModel product) async {
    try {
      isLoading.value = true;
      final success = await ProductService.addProduct(product);
      
      if (success) {
        final branch = Get.find<BranchController>().selectedBranch.value;
        await fetchProducts(branch: branch);
        await fetchStats();
        Get.snackbar(
          'نجح',
          'تم إضافة المنتج بنجاح',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      }
      
      return success;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في إضافة المنتج: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // تحديث منتج
  Future<bool> updateProduct(ProductModel product) async {
    try {
      print('🔍 ProductController - بدء تحديث المنتج:');
      print('   - ID: ${product.id}');
      print('   - العنوان: ${product.title}');
      print('   - الرسائل: ${product.branchMessages}');
      
      isLoading.value = true;
      
      print('💾 ProductController - بدء حفظ في ProductService...');
      final success = await ProductService.updateProduct(product);
      
      print('✅ ProductController - نتيجة الحفظ من ProductService: $success');
      
      if (success) {
        print('🔄 ProductController - تحديث البيانات المحلية...');
        // تحديث البيانات في الخلفية لتجنب التأخير
        final branch = Get.find<BranchController>().selectedBranch.value;
        Future.microtask(() async {
          await fetchProducts(branch: branch);
          await fetchStats();
        });
        
        print('🎉 ProductController - تم تحديث المنتج بنجاح!');
        // إزالة رسالة النجاح المكررة من هنا لأنها ستظهر من ProductCard
      } else {
        print('❌ ProductController - فشل في تحديث المنتج');
      }
      
      return success;
    } catch (e) {
      print('❌ ProductController - خطأ في تحديث المنتج: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحديث المنتج: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // حذف منتج
  Future<bool> deleteProduct(String productId) async {
    try {
      isLoading.value = true;
      final success = await ProductService.deleteProduct(productId);
      
      if (success) {
        final branch = Get.find<BranchController>().selectedBranch.value;
        await fetchProducts(branch: branch);
        await fetchStats();
        Get.snackbar(
          'نجح',
          'تم حذف المنتج بنجاح',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      }
      
      return success;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في حذف المنتج: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // تبديل حالة المنتج
  Future<bool> toggleProductStatus(String productId, bool active) async {
    try {
      final success = await ProductService.updateProductStatus(productId, active);
      
      if (success) {
        final branch = Get.find<BranchController>().selectedBranch.value;
        await fetchProducts(branch: branch);
        await fetchStats();
        Get.snackbar(
          'نجح',
          active ? 'تم تفعيل المنتج' : 'تم إلغاء تفعيل المنتج',
          backgroundColor: Get.theme.primaryColor,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      }
      
      return success;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة المنتج: $e',
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }
  }


  // مسح الفلاتر
  void clearFilters() {
    searchQuery.value = '';
    selectedCategory.value = 0;
    selectedSubCategory.value = 0;
    sortBy.value = 'createdAt';
    sortDescending.value = true;
    _applyFilters();
  }

  // الحصول على اسم الفئة
  String getCategoryName(int categoryId) {
    try {
      final category = categoryController.categories.firstWhere((c) => c.originalId == categoryId);
      return category.title;
    } catch (e) {
      return 'فئة $categoryId';
    }
  }

  // تحديث البيانات
  Future<void> refresh() async {
    final branchController = Get.find<BranchController>();
    await fetchProducts(branch: branchController.selectedBranch.value);
    await fetchCategories();
    await fetchStats();
  }
}
