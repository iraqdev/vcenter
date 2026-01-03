import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/branch_controller.dart';
import '../models/product_model.dart';
import '../widgets/product_card.dart';
import '../widgets/product_edit_dialog.dart';

class ProductsManagementScreen extends StatelessWidget {
  ProductsManagementScreen({super.key});

  final ProductController productController = Get.find<ProductController>();
  final CategoryController categoryController = Get.find<CategoryController>();
  final NotificationController notificationController = Get.find<NotificationController>();
  final BranchController branchController = Get.find<BranchController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(),
        backgroundColor: Get.theme.primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('إضافة منتج'),
      ),
      appBar: AppBar(
        title: Text('إدارة المنتجات'),
        backgroundColor: Get.theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر إرسال إشعار مخصص حسب الفرع
          IconButton(
            icon: Icon(Icons.notifications_active),
            tooltip: 'إرسال إشعار مخصص',
            onPressed: () => _showCustomNotificationDialog(),
          ),
          // زر البحث
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          // زر الفلترة
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          // زر إضافة منتج جديد
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط الإحصائيات
          _buildStatsBar(),
          
          // شريط البحث والفلترة
          _buildSearchAndFilterBar(),
          
          // قائمة المنتجات
          Expanded(
            child: Obx(() {
              if (productController.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              
              if (productController.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16),
                      Text(
                        productController.errorMessage.value,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => productController.refresh(),
                        child: Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }
              
              if (productController.filteredProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد منتجات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'اضغط على + لإضافة منتج جديد',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () => productController.refresh(),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: productController.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = productController.filteredProducts[index];
                    return ProductCard(
                      product: product,
                      onEdit: () => _showEditProductDialog(product),
                      onToggleStatus: () => _toggleProductStatus(product),
                      onDelete: () => _showDeleteConfirmation(product),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // شريط الإحصائيات
  Widget _buildStatsBar() {
    return Obx(() {
      final stats = productController.stats;
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.theme.primaryColor.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: Get.theme.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildStatItem(
              'إجمالي المنتجات',
              '${stats['total'] ?? 0}',
              Icons.inventory_2,
              Colors.blue,
            ),
            SizedBox(width: 16),
            _buildStatItem(
              'منتجات نشطة',
              '${stats['active'] ?? 0}',
              Icons.check_circle,
              Colors.green,
            ),
            SizedBox(width: 16),
            _buildStatItem(
              'نفد المخزون',
              '${stats['outOfStock'] ?? 0}',
              Icons.warning,
              Colors.red,
            ),
            SizedBox(width: 16),
            _buildStatItem(
              'مخزون منخفض',
              '${stats['lowStock'] ?? 0}',
              Icons.info,
              Colors.orange,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // شريط البحث والفلترة
  Widget _buildSearchAndFilterBar() {
    return Obx(() {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            // حقل البحث
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'البحث في المنتجات...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) => productController.searchProducts(value),
              ),
            ),
            SizedBox(width: 12),
            
            // فلتر الفئة
            DropdownButton<int>(
              value: productController.selectedCategory.value == 0 
                  ? null 
                  : productController.selectedCategory.value,
              hint: Text('الفئة'),
              items: [
                DropdownMenuItem<int>(
                  value: 0,
                  child: Text('جميع الفئات'),
                ),
                ...categoryController.categories.map((category) =>
                  DropdownMenuItem<int>(
                    value: category.originalId,
                    child: Text(category.title),
                  ),
                ),
              ],
              onChanged: (value) => productController.filterByCategory(value ?? 0),
            ),
            SizedBox(width: 12),
            
            // زر مسح الفلاتر
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () => productController.clearFilters(),
              tooltip: 'مسح الفلاتر',
            ),
          ],
        ),
      );
    });
  }

  // نافذة البحث
  void _showSearchDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('البحث المتقدم'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'البحث في المنتجات',
                hintText: 'اسم المنتج، الوصف، الفئة...',
              ),
              onChanged: (value) => productController.searchProducts(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // نافذة الفلترة
  void _showFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('فلترة المنتجات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // فلتر الفئة
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'الفئة'),
              value: productController.selectedCategory.value == 0 
                  ? null 
                  : productController.selectedCategory.value,
              items: [
                DropdownMenuItem<int>(
                  value: 0,
                  child: Text('جميع الفئات'),
                ),
                ...categoryController.categories.map((category) =>
                  DropdownMenuItem<int>(
                    value: category.originalId,
                    child: Text(category.title),
                  ),
                ),
              ],
              onChanged: (value) => productController.filterByCategory(value ?? 0),
            ),
            SizedBox(height: 16),
            
            // ترتيب المنتجات
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'ترتيب حسب'),
              value: productController.sortBy.value,
              items: [
                DropdownMenuItem(value: 'createdAt', child: Text('تاريخ الإنشاء')),
                DropdownMenuItem(value: 'title', child: Text('الاسم')),
                DropdownMenuItem(value: 'price', child: Text('السعر')),
              ],
              onChanged: (value) => productController.sortProducts(value!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => productController.clearFilters(),
            child: Text('مسح الفلاتر'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // نافذة إضافة منتج جديد
  void _showAddProductDialog() {
    Get.dialog(
      ProductEditDialog(
        product: null,
        onSave: (product) => productController.addProduct(product),
      ),
    );
  }

  // نافذة تعديل منتج
  void _showEditProductDialog(ProductModel product) {
    Get.dialog(
      ProductEditDialog(
        product: product,
        onSave: (updatedProduct) => productController.updateProduct(updatedProduct),
      ),
    );
  }

  // تبديل حالة المنتج
  void _toggleProductStatus(ProductModel product) {
    productController.toggleProductStatus(product.id, !product.active);
  }

  // تأكيد الحذف
  void _showDeleteConfirmation(ProductModel product) {
    Get.dialog(
      AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف المنتج "${product.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              productController.deleteProduct(product.id);
            },
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // نافذة إرسال إشعار مخصص حسب الفرع
  void _showCustomNotificationDialog() {
    final TextEditingController messageController = TextEditingController();
    final RxString selectedBranch = branchController.selectedBranch.value.obs;
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: Get.theme.primaryColor),
            SizedBox(width: 10),
            Text('إرسال إشعار مخصص'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // اختيار الفرع
                Text(
                  'اختر الفرع:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 10),
                Obx(() => Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedBranch.value,
                      isExpanded: true,
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      items: BranchController.branches.map((String branch) {
                        return DropdownMenuItem<String>(
                          value: branch,
                          child: Row(
                            children: [
                              Text(
                                branchController.getBranchIcon(branch),
                                style: TextStyle(fontSize: 18),
                              ),
                              SizedBox(width: 10),
                              Text(branch),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedBranch.value = newValue;
                        }
                      },
                    ),
                  ),
                )),
                SizedBox(height: 20),
                
                // حقل الرسالة
                Text(
                  'الرسالة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك هنا...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'سيتم إرسال الإشعار لجميع مستخدمي فرع ${selectedBranch.value}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (messageController.text.trim().isEmpty) {
                Get.snackbar(
                  'خطأ',
                  'الرجاء كتابة رسالة',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              
              Get.back(); // إغلاق النافذة
              
              // إرسال الإشعار
              Get.dialog(
                Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );
              
              try {
                await notificationController.sendToAllUsers(
                  title: 'إشعار من VCenter',
                  message: messageController.text.trim(),
                  branch: selectedBranch.value == 'العراق' ? null : selectedBranch.value,
                );
                
                Get.back(); // إغلاق loading
                Get.snackbar(
                  'نجح',
                  'تم إرسال الإشعار بنجاح إلى فرع ${selectedBranch.value}',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.back(); // إغلاق loading
                Get.snackbar(
                  'خطأ',
                  'فشل في إرسال الإشعار: ${e.toString()}',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send, size: 18),
                SizedBox(width: 5),
                Text('إرسال'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
