import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../utils/image_utils.dart';
import '../controllers/product_controller.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنتج والمعلومات الأساسية
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // صور المنتج
                _buildProductImages(),
                SizedBox(width: 16),
                
                // معلومات المنتج
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // اسم المنتج
                      Text(
                        product.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      
                      // الفئة
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(() {
                          final productController = Get.find<ProductController>();
                          return Text(
                            productController.getCategoryName(product.category),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 8),
                      
                      // السعر
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.formattedPrice,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // حالة المنتج
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.active 
                            ? Colors.green[100] 
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.active ? 'نشط' : 'غير نشط',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: product.active 
                              ? Colors.green[700] 
                              : Colors.red[700],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // قائمة الإجراءات
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                            break;
                          case 'toggle':
                            onToggleStatus();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('تعديل'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                product.active ? Icons.block : Icons.check_circle,
                                color: product.active ? Colors.red : Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text(product.active ? 'إلغاء التفعيل' : 'تفعيل'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('حذف'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // وصف المنتج
          if (product.description.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                product.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          
          
          // أزرار التحكم السريع
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // زر التعديل
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit,
                        label: 'تعديل',
                        color: Colors.blue,
                        onTap: onEdit,
                      ),
                    ),
                    SizedBox(width: 8),
                    
                    // زر التفعيل/إلغاء التفعيل
                    Expanded(
                      child: _buildActionButton(
                        icon: product.active ? Icons.block : Icons.check_circle,
                        label: product.active ? 'إلغاء تفعيل' : 'تفعيل',
                        color: product.active ? Colors.red : Colors.green,
                        onTap: onToggleStatus,
                      ),
                    ),
                    SizedBox(width: 8),
                    
                    // زر الحذف
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete,
                        label: 'حذف',
                        color: Colors.red[700]!,
                        onTap: onDelete,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // زر إرسال رسالة للفرع
                _buildFullWidthButton(
                  icon: Icons.message,
                  label: 'إرسال رسالة للفرع',
                  color: Colors.orange,
                  onTap: () => _showBranchMessageDialog(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // نافذة إرسال رسالة للفرع
  void _showBranchMessageDialog() {
    final productController = Get.find<ProductController>();
    final TextEditingController messageController = TextEditingController();
    final RxString selectedBranch = 'الغزالية'.obs;
    
    // تحميل الرسالة الحالية إن وجدت
    final currentMessage = product.getBranchMessage(selectedBranch.value);
    if (currentMessage != null) {
      messageController.text = currentMessage;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.message, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(child: Text('رسالة للمنتج - ${product.title}')),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      items: ['الغزالية', 'الزعفرانية', 'الاعظمية', 'العراق'].map((String branch) {
                        return DropdownMenuItem<String>(
                          value: branch,
                          child: Text(branch),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          selectedBranch.value = newValue;
                          // تحميل الرسالة الحالية للفرع الجديد
                          final branchMessage = product.getBranchMessage(newValue);
                          messageController.text = branchMessage ?? '';
                        }
                      },
                    ),
                  ),
                )),
                SizedBox(height: 20),
                
                Text(
                  'الرسالة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'مثال: يتأخر التوصيل لهذا المنتج',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'سيتم عرض الرسالة فقط لمستخدمي فرع ${selectedBranch.value}',
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
          if (product.hasBranchMessage(selectedBranch.value))
            TextButton(
              onPressed: () async {
                Get.back();
                // حذف الرسالة
                final updatedMessages = Map<String, String>.from(product.branchMessages ?? {});
                updatedMessages.remove(selectedBranch.value);
                await productController.updateProduct(
                  product.copyWith(branchMessages: updatedMessages),
                );
                Get.snackbar(
                  'تم',
                  'تم حذف الرسالة بنجاح',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              child: Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
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
              
              print('🔍 ProductCard - بدء حفظ الرسالة:');
              print('   - المنتج: ${product.title}');
              print('   - الفرع: ${selectedBranch.value}');
              print('   - الرسالة: ${messageController.text.trim()}');
              print('   - الرسائل الحالية: ${product.branchMessages}');
              
              Get.back();
              
              // حفظ الرسالة
              Get.dialog(
                Center(child: CircularProgressIndicator()),
                barrierDismissible: false,
              );
              
              try {
                final updatedMessages = Map<String, String>.from(product.branchMessages ?? {});
                updatedMessages[selectedBranch.value] = messageController.text.trim();
                
                print('📝 ProductCard - الرسائل المحدثة: $updatedMessages');
                
                final updatedProduct = product.copyWith(branchMessages: updatedMessages);
                print('📦 ProductCard - المنتج المحدث: ${updatedProduct.branchMessages}');
                
                print('💾 ProductCard - بدء حفظ في قاعدة البيانات...');
                
                // إضافة timeout لتجنب التعليق
                final success = await productController.updateProduct(updatedProduct)
                    .timeout(
                      Duration(seconds: 10),
                      onTimeout: () {
                        print('⏰ ProductCard - انتهت مهلة الحفظ');
                        return false;
                      },
                    );
                
                print('✅ ProductCard - نتيجة الحفظ: $success');
                
                // إغلاق نافذة التحميل
                Get.back();
                
                if (success) {
                  print('🎉 ProductCard - تم حفظ الرسالة بنجاح!');
                  Get.snackbar(
                    'نجح',
                    'تم حفظ الرسالة بنجاح لفرع ${selectedBranch.value}',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } else {
                  print('❌ ProductCard - فشل في حفظ الرسالة');
                  Get.snackbar(
                    'خطأ',
                    'فشل في حفظ الرسالة',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              } catch (e) {
                print('❌ ProductCard - خطأ في حفظ الرسالة: $e');
                // إغلاق نافذة التحميل في حالة الخطأ
                Get.back();
                Get.snackbar(
                  'خطأ',
                  'فشل في حفظ الرسالة: ${e.toString()}',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save, size: 18),
                SizedBox(width: 5),
                Text('حفظ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // بناء صور المنتج
  Widget _buildProductImages() {
    final images = product.allImages;
    
    if (images.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[400],
          size: 40,
        ),
      );
    }

    if (images.length == 1) {
      // صورة واحدة
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: ImageUtils.getCorrectImageUrl(
              images.first,
              'product',
              product.originalId ?? 0,
            ),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
              ),
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: 40,
            ),
          ),
        ),
      );
    }

    // عدة صور
    return Container(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          // الصورة الرئيسية
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: ImageUtils.getCorrectImageUrl(
                  images.first,
                  'product',
                  product.originalId ?? 0,
                ),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                  size: 40,
                ),
              ),
            ),
          ),
          
          // مؤشر عدد الصور
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${images.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // أيقونة الصور المتعددة
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.photo_library,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
