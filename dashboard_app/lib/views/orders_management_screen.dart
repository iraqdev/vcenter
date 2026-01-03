import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';
import '../controllers/branch_controller.dart';
import '../models/order_model.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_dialog.dart';
import '../widgets/order_details_dialog.dart';

class OrdersManagementScreen extends StatelessWidget {
  OrdersManagementScreen({super.key});

  final OrderController orderController = Get.find<OrderController>();
  final BranchController branchController = Get.find<BranchController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الطلبات'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // مؤشر الطلبات الجديدة
          Obx(() {
            if (orderController.newOrdersCount.value > 0) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      orderController.clearNewOrdersCount();
                      Get.snackbar(
                        'تم مسح العداد',
                        'تم مسح عداد الطلبات الجديدة',
                        backgroundColor: Colors.blue,
                        colorText: Colors.white,
                      );
                    },
                    icon: Icon(Icons.notifications_active),
                    tooltip: 'طلبات جديدة',
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${orderController.newOrdersCount.value}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return SizedBox.shrink();
          }),
          IconButton(
            onPressed: () => orderController.testSound(),
            icon: Icon(Icons.volume_up),
            tooltip: 'اختبار الصوت',
          ),
          IconButton(
            onPressed: () => orderController.refresh(branch: branchController.selectedBranch.value),
            icon: Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط الإحصائيات
          _buildStatsBar(),
          
          // شريط البحث والفلترة
          _buildSearchAndFilterBar(),
          
          // قائمة الطلبات
          Expanded(
            child: Obx(() {
              if (orderController.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepPurple,
                  ),
                );
              }
              
              if (orderController.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      SizedBox(height: 16),
                      Text(
                        orderController.errorMessage.value,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => orderController.refresh(),
                        child: Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }
              
              if (orderController.filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد طلبات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'لم يتم العثور على أي طلبات',
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
                onRefresh: () => orderController.refresh(),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: orderController.filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = orderController.filteredOrders[index];
                    return OrderCard(
                      order: order,
                      onViewDetails: () => _showOrderDetails(order),
                      onUpdateStatus: () => _showStatusDialog(order),
                      onDelete: () => _showDeleteConfirmation(order),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterDialog,
        icon: Icon(Icons.filter_list),
        label: Text('فلترة'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatsBar() {
    return Obx(() => Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'إجمالي الطلبات',
              orderController.stats['total']?.toString() ?? '0',
              Icons.shopping_cart,
              Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'قيد المراجعة',
              orderController.stats['pending']?.toString() ?? '0',
              Icons.pending,
              Colors.orange[300]!,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'قيد التجهيز',
              orderController.stats['preparing']?.toString() ?? '0',
              Icons.restaurant,
              Colors.blue[300]!,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'قيد التوصيل',
              orderController.stats['delivering']?.toString() ?? '0',
              Icons.delivery_dining,
              Colors.purple[300]!,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // شريط البحث
          TextField(
            decoration: InputDecoration(
              hintText: 'البحث في الطلبات...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: () => orderController.searchOrders(''),
                icon: Icon(Icons.clear),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => orderController.searchOrders(value),
          ),
          
          SizedBox(height: 12),
          
          // فلاتر سريعة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', -1),
                SizedBox(width: 8),
                _buildFilterChip('قيد المراجعة', 0),
                SizedBox(width: 8),
                _buildFilterChip('قيد التحضير', 1),
                SizedBox(width: 8),
                _buildFilterChip('قيد التوصيل', 2),
                SizedBox(width: 8),
                _buildFilterChip('تم التوصيل', 3),
                SizedBox(width: 8),
                _buildFilterChip('ملغي', 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int value) {
    return Obx(() => FilterChip(
      label: Text(label),
      selected: orderController.selectedStatus.value == value,
      onSelected: (selected) {
        if (selected) {
          orderController.filterByStatus(value);
        }
      },
      selectedColor: Colors.deepPurple.withOpacity(0.2),
      checkmarkColor: Colors.deepPurple,
    ));
  }

  void _showOrderDetails(OrderModel order) {
    Get.dialog(OrderDetailsDialog(order: order));
  }

  void _showStatusDialog(OrderModel order) {
    Get.dialog(OrderStatusDialog(order: order));
  }

  void _showDeleteConfirmation(OrderModel order) {
    Get.dialog(
      AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا الطلب؟\n\nهذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              orderController.deleteOrder(order.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('فلترة الطلبات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // فلتر الحالة
            DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'الحالة'),
              value: orderController.selectedStatus.value == -1 
                  ? null 
                  : orderController.selectedStatus.value,
              items: [
                DropdownMenuItem<int>(
                  value: -1,
                  child: Text('الكل'),
                ),
                DropdownMenuItem<int>(
                  value: 0,
                  child: Text('قيد المراجعة'),
                ),
                DropdownMenuItem<int>(
                  value: 1,
                  child: Text('قيد التحضير'),
                ),
                DropdownMenuItem<int>(
                  value: 2,
                  child: Text('قيد التوصيل'),
                ),
                DropdownMenuItem<int>(
                  value: 3,
                  child: Text('تم التوصيل'),
                ),
                DropdownMenuItem<int>(
                  value: 4,
                  child: Text('ملغي'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  orderController.filterByStatus(value);
                }
              },
            ),
            
            SizedBox(height: 16),
            
            // ترتيب
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'ترتيب حسب'),
              value: orderController.sortBy.value,
              items: [
                DropdownMenuItem<String>(
                  value: 'createdAt',
                  child: Text('تاريخ الطلب'),
                ),
                DropdownMenuItem<String>(
                  value: 'userName',
                  child: Text('اسم العميل'),
                ),
                DropdownMenuItem<String>(
                  value: 'totalAmount',
                  child: Text('المبلغ الإجمالي'),
                ),
                DropdownMenuItem<String>(
                  value: 'status',
                  child: Text('الحالة'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  orderController.sortOrders(value);
                }
              },
            ),
            
            SizedBox(height: 16),
            
            // اتجاه الترتيب
            Row(
              children: [
                Text('ترتيب تصاعدي'),
                Switch(
                  value: !orderController.sortDescending.value,
                  onChanged: (value) {
                    orderController.sortOrders(
                      orderController.sortBy.value,
                      descending: !value,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              orderController.clearFilters();
              Get.back();
            },
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
}
