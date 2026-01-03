import 'package:ecommerce/models/SubCategory.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../Services/FirebaseService.dart';
import '../models/Product.dart';
import '../utils/image_utils.dart';

class Products_Controller extends GetxController {
  dynamic argumentData = Get.arguments;
  var isLoadingItem = false.obs;
  var isLoadingProducts = false.obs;
  var isLoadingMore = false.obs; // حالة تحميل المزيد
  var id_cat = 0.obs;

  TextEditingController searchQueryController = TextEditingController();
  var productList = <Product>[].obs;
  var selectedFilter = RxString('');
  var citiesList = <SubCategory>[].obs;
  int city_id = -1;

  var currentPage = 1.obs; // تتبع الصفحة الحالية

  ScrollController scrollController =
      ScrollController(); // ScrollController للتحكم في التمرير

  @override
  void onInit() {
    try {
      print("Products_Controller onInit - argumentData: $argumentData");
      if (argumentData != null && argumentData.isNotEmpty) {
        id_cat.value = argumentData[0]['id'] ?? 0;
        print("Category ID: ${id_cat.value}");
        fetchCities(id_cat.value);
      } else {
        print("No argumentData provided");
        id_cat.value = 0;
      }
      scrollController.addListener(_scrollListener); // إضافة مستمع للتمرير
    } catch (e) {
      print("Error in Products_Controller onInit: $e");
      id_cat.value = 0;
    }
    super.onInit();
  }

  @override
  void onClose() {
    scrollController.removeListener(
      _scrollListener,
    ); // إزالة المستمع عند غلق الـ Controller
    super.onClose();
  }

  // دالة ترتيب الفئات الفرعية حسب التسلسل المحدد
  List<SubCategory> _sortSubCategoriesByOrder(List<SubCategory> subCategories, int categoryId) {
    // تحديد التسلسل حسب الفئة الرئيسية
    List<String> orderList;
    
    // إذا كانت الفئة الرئيسية هي iPhone (افترض أن id = 1)
    if (categoryId == 1) {
      orderList = [
        'شاشة',
        'بطارية', 
        'فلات شحن',
        'فلات سبيكر',
        'ظهر',
        'تاج',
        'كاميرا امامية',
        'جرس سفلي',
        'كاميرا خلفية',
        'فلات بور',
        'شاصي'
      ];
    } else {
      // لجميع الفئات الأخرى
      orderList = [
        'شاشة',
        'فلات شحن',
        'بطارية',
        'شريط',
        'فلات بور',
        'شاصي',
        'جرص سفلي',
        'سماعة علوية',
        'ظهر',
        'كاميرا امامية',
        'كاميرا خلفية'
      ];
    }
    
    // ترتيب الفئات الفرعية حسب التسلسل المحدد
    subCategories.sort((a, b) {
      int indexA = orderList.indexOf(a.title);
      int indexB = orderList.indexOf(b.title);
      
      // إذا لم توجد الفئة في القائمة، ضعها في النهاية
      if (indexA == -1) indexA = 999;
      if (indexB == -1) indexB = 999;
      
      return indexA.compareTo(indexB);
    });
    
    return subCategories;
  }

  void filterBillsByStatus(statusCode) {
    print("filterBillsByStatus called with statusCode: $statusCode");
    city_id = statusCode;
    // If there's a search query, filter by both subcategory and search
    if (searchQueryController.text.isNotEmpty) {
      print("Search query exists, filtering by search");
      filterProductList(searchQueryController.text);
    } else {
      // Otherwise just filter by subcategory
      print("No search query, fetching products for subcategory: $statusCode");
      fetchProduct(statusCode);
    }
    isLoadingProducts(true);
    update();
  }

  void filterProductList(String query) {
    print('Products_Controller filterProductList called with: "$query"');
    print('Category ID: ${id_cat.value}, SubCategory ID: $city_id');

    if (query.isEmpty) {
      // If search is empty, filter only by subcategory
      print('Query is empty, fetching products for subcategory: $city_id');
      fetchProduct(city_id);
    } else {
      // Filter by both subcategory and search text
      print('Filtering products with query: "$query"');
      isLoadingProducts(true);
      // استخدام Firebase للبحث في المنتجات
      FirebaseService.getProducts().then((allProducts) {
        if (allProducts != null && allProducts.isNotEmpty) {
          // تصفية المنتجات حسب الفئة والبحث
          var filteredProducts = allProducts.where((product) {
            bool matchesCategory = product['category'] == id_cat.value;
            bool matchesSubCategory = city_id == -1 || product['subCategory'] == city_id;
            bool matchesQuery = product['title'].toLowerCase().contains(query.toLowerCase()) ||
                               product['description'].toLowerCase().contains(query.toLowerCase());
            return matchesCategory && matchesSubCategory && matchesQuery;
          }).toList();
          
          // تحويل إلى نموذج Product
          List<Product> products = filteredProducts.map((data) {
            final productId = data['originalId'] ?? 0;
            final currentImageUrl = data['image'] ?? '';
            final correctImageUrl = ImageUtils.getCorrectImageUrl(
              currentImageUrl,
              'product',
              productId,
            );
            return Product(
              id: productId,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              price: int.tryParse(data['price']?.toString() ?? '0') ?? 0,
              category: int.tryParse(data['category']?.toString() ?? '0') ?? 0,
              image: correctImageUrl,
            branchMessages: data['branchMessages'] != null 
                ? Map<String, String>.from(data['branchMessages'])
                : null,
            );
          }).toList();
          
          productList.value = products;
        } else {
          productList.clear();
        }
        isLoadingProducts(false);
        update();
      }).catchError((error) {
        print('Error filtering products: $error');
        productList.clear();
        isLoadingProducts(false);
        update();
      });
    }
  }

  void fetchProduct(int id) async {
    print("fetchProduct called with id: $id, category: ${id_cat.value}");
    isLoadingProducts(true);
    productList.clear();
    currentPage.value = 1; // Reset current page when fetching new products
    try {
      var allProducts = await FirebaseService.getProducts();
      print("Fetched all products: ${allProducts?.length ?? 0} products");
      
      if (allProducts != null && allProducts.isNotEmpty) {
        // تصفية المنتجات حسب الفئة والفئة الفرعية
        var filteredProducts = allProducts.where((product) {
          bool matchesCategory = product['category'] == id_cat.value;
          bool matchesSubCategory = id == -1 || product['subCategory'] == id;
          // طباعة فقط للمنتجات المطابقة للفئة
          if (matchesCategory) {
            print("Product: ${product['title']}, subCategory: ${product['subCategory']}, looking for: $id, matches: $matchesSubCategory");
          }
          return matchesCategory && matchesSubCategory;
        }).toList();
        
        print("Filtered products: ${filteredProducts.length} products for subcategory $id");
        
        // تحويل إلى نموذج Product
        List<Product> products = filteredProducts.map((data) {
          final productId = data['originalId'] ?? 0;
          final currentImageUrl = data['image'] ?? '';
          
          // إنشاء رابط صحيح للصورة
          final correctImageUrl = ImageUtils.getCorrectImageUrl(
            currentImageUrl, 
            'product', 
            productId
          );
          
          return Product(
            id: productId,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            price: int.tryParse(data['price']?.toString() ?? '0') ?? 0,
            category: int.tryParse(data['category']?.toString() ?? '0') ?? 0,
            image: correctImageUrl,
            branchMessages: data['branchMessages'] != null 
                ? Map<String, String>.from(data['branchMessages'])
                : null,
          );
        }).toList();
        if (products.isNotEmpty) {
          productList.value = products;
          print("Products loaded successfully: ${productList.length} products");
        } else {
          productList.clear(); // Clear the list if no results found
          print("No products found for subcategory $id");
        }
      } else {
        productList.clear();
        print("No products data available");
      }
    } catch (e) {
      print("Error fetching products: $e");
      productList.clear(); // Clear the list on error
    } finally {
      isLoadingProducts(false);
      print("fetchProduct completed, isLoadingProducts: ${isLoadingProducts.value}");
    }
    update();
  }

  void fetchCities(int categoryId) async {
    print("fetchCities called with categoryId: $categoryId");
    isLoadingItem(true);
    try {
      // جلب الفئات الفرعية والمنتجات معاً
      var citiesData = await FirebaseService.getSubCategories();
      var allProducts = await FirebaseService.getProducts();
      
      print("Fetched cities data: ${citiesData?.length ?? 0} cities");
      print("Fetched products data: ${allProducts?.length ?? 0} products");
      
      if (citiesData != null && citiesData.isNotEmpty && allProducts != null && allProducts.isNotEmpty) {
        // تصفية الفئات الفرعية حسب الفئة الرئيسية
        var filteredCities = citiesData.where((city) {
          bool matches = city['category'] == categoryId;
          return matches;
        }).toList();
        
        print("Filtered cities: ${filteredCities.length} cities for category $categoryId");
        
        // فلترة الفئات الفرعية التي تحتوي على منتجات فقط
        List<SubCategory> citiesWithProducts = [];
        
        for (var cityData in filteredCities) {
          int subCategoryId = cityData['originalId'] ?? 0;
          
          // البحث عن منتجات في هذه الفئة الفرعية
          bool hasProducts = allProducts.any((product) {
            return product['category'] == categoryId && product['subCategory'] == subCategoryId;
          });
          
          print("🔍 فحص فئة فرعية: ${cityData['title']} (ID: $subCategoryId), تحتوي على منتجات: $hasProducts");
          
          if (hasProducts) {
            citiesWithProducts.add(SubCategory(
              id: subCategoryId,
              title: cityData['title'] ?? '',
              category: int.tryParse(cityData['category']?.toString() ?? '0') ?? 0,
            ));
            print("✅ تم إضافة فئة فرعية: ${cityData['title']}");
          }
        }
        
        // ترتيب الفئات الفرعية حسب التسلسل المحدد
        citiesWithProducts = _sortSubCategoriesByOrder(citiesWithProducts, categoryId);
        
        print("Cities with products: ${citiesWithProducts.length} cities");
        
        if (citiesWithProducts.isNotEmpty) {
          citiesList.value = citiesWithProducts;
          print("Cities list updated: ${citiesList.length} cities");
          selectedFilter(citiesWithProducts[0].title);
          print("Selected filter: ${citiesWithProducts[0].title} (id: ${citiesWithProducts[0].id})");
          filterBillsByStatus(citiesWithProducts[0].id);
          fetchProduct(citiesWithProducts[0].id);
        } else {
          // إذا لم توجد فئات فرعية تحتوي على منتجات، جلب جميع المنتجات للفئة الرئيسية
          print("No subcategories with products found, fetching products by main category");
          fetchProductByCategory(categoryId);
        }
      } else {
        print("No cities or products data found, fetching products by main category");
        fetchProductByCategory(categoryId);
      }
    } catch (e) {
      print("Error fetching cities: $e");
      // في حالة الخطأ، جلب المنتجات حسب الفئة الرئيسية
      fetchProductByCategory(categoryId);
    } finally {
      isLoadingItem(false);
    }
    update();
  }

  // جلب المنتجات حسب الفئة الرئيسية
  void fetchProductByCategory(int categoryId) async {
    print("🔍 Products_Controller - fetchProductByCategory called with categoryId: $categoryId");
    isLoadingProducts(true);
    try {
      var productsData = await FirebaseService.getProducts();
      print("✅ Products_Controller - Fetched products data: ${productsData?.length ?? 0} products");
      
      if (productsData != null && productsData.isNotEmpty) {
        // تصفية المنتجات حسب الفئة الرئيسية
        var filteredProducts = productsData.where((product) {
          bool matches = product['category'] == categoryId;
          if (matches) {
            print("🎯 منتج مطابق: ${product['title']}, category: ${product['category']}, originalId: ${product['originalId']}");
          }
          return matches;
        }).toList();
        
        print("📊 Products_Controller - Filtered products: ${filteredProducts.length} products for category $categoryId");
        
        // تحويل إلى نموذج Product
        List<Product> products = filteredProducts.map((data) {
          final productId = data['originalId'] ?? 0;
          final currentImageUrl = data['image'] ?? '';
          
          // إنشاء رابط صحيح للصورة
          final correctImageUrl = ImageUtils.getCorrectImageUrl(
            currentImageUrl, 
            'product', 
            productId
          );
          
          return Product(
            id: productId,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            price: int.tryParse(data['price']?.toString() ?? '0') ?? 0,
            category: int.tryParse(data['category']?.toString() ?? '0') ?? 0,
            image: correctImageUrl,
            branchMessages: data['branchMessages'] != null 
                ? Map<String, String>.from(data['branchMessages'])
                : null,
          );
        }).toList();
        
        productList.value = products;
        print('Products loaded by category: ${productList.length} products');
      } else {
        productList.clear();
        print('No products found for category $categoryId');
      }
    } catch (e) {
      print('Error fetching products by category: $e');
      productList.clear();
    } finally {
      isLoadingProducts(false);
    }
    update();
  }

  void loadMoreProducts(id) async {
    if (!isLoadingMore.value) {
      isLoadingMore(true);
      try {
        int nextPage =
            currentPage.value + 1; // الصفحة التالية بناءً على المتغير الحالي
        var allProducts = await FirebaseService.getProducts();
        if (allProducts != null && allProducts.isNotEmpty) {
          // تصفية المنتجات حسب الفئة والفئة الفرعية
          var filteredProducts = allProducts.where((product) {
            bool matchesCategory = product['category'] == id_cat.value;
            bool matchesSubCategory = id == -1 || product['subCategory'] == id;
            return matchesCategory && matchesSubCategory;
          }).toList();
          
          // تحويل إلى نموذج Product
          List<Product> products = filteredProducts.map((data) {
            final productId = data['originalId'] ?? 0;
            final currentImageUrl = data['image'] ?? '';
            final correctImageUrl = ImageUtils.getCorrectImageUrl(
              currentImageUrl,
              'product',
              productId,
            );
            return Product(
              id: productId,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              price: int.tryParse(data['price']?.toString() ?? '0') ?? 0,
              category: int.tryParse(data['category']?.toString() ?? '0') ?? 0,
              image: correctImageUrl,
            branchMessages: data['branchMessages'] != null 
                ? Map<String, String>.from(data['branchMessages'])
                : null,
            );
          }).toList();

        if (products.isNotEmpty) {
          // التحقق من التكرار قبل إضافة المنتجات الجديدة
          var newProducts =
              products.where((product) {
                return !productList.any(
                  (existingProduct) => existingProduct.id == product.id,
                );
              }).toList();

          if (newProducts.isNotEmpty) {
            productList.addAll(newProducts); // إضافة المنتجات الجديدة
            currentPage.value = nextPage; // تحديث الصفحة الحالية
          }
        }
      } else {
        print('No more products to load');
      }
    } catch (e) {
      print("Error loading more products: $e");
    } finally {
      isLoadingMore(false);
    }
  }
  update();
}

  void _scrollListener() {
    double maxScroll = scrollController.position.maxScrollExtent;
    double currentScroll = scrollController.position.pixels;

    if (currentScroll >= maxScroll - 50) {
      print("Reached the bottom of the list, loading more products...");
      loadMoreProducts(city_id);
    }
  }
}
