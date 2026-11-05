import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/dashboard_dialog.dart';
import '../controllers/customer_order_controller.dart';
import '../models/order_model.dart';
import '../widgets/order_card.dart';
import '../widgets/order_status_dialog.dart';
import '../widgets/order_bulk_selection_bar.dart';
import 'order_details_screen.dart';

class CustomerOrdersScreen extends StatelessWidget {
  CustomerOrdersScreen({super.key});

  final CustomerOrderController controller = Get.put(CustomerOrderController());

  static const Color _accent = Color(0xFF00796B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.selectionMode.value
                  ? 'تحديد طلبات الزبائن (${controller.selectedCount})'
                  : 'طلبات الزبائن',
            )),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Obx(() {
          if (controller.selectionMode.value) {
            return IconButton(
              icon: const Icon(Icons.close),
              onPressed: controller.exitSelectionMode,
              tooltip: 'إلغاء التحديد',
            );
          }
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          );
        }),
        automaticallyImplyLeading: false,
        actions: [
          Obx(() {
            if (controller.selectionMode.value) {
              return IconButton(
                onPressed: () {
                  if (controller.selectedCount ==
                      controller.filteredOrders.length) {
                    controller.clearSelectedOrders();
                  } else {
                    controller.selectAllVisible();
                  }
                },
                icon: const Icon(Icons.select_all),
                tooltip: 'تحديد الكل',
              );
            }
            return IconButton(
              onPressed: controller.toggleSelectionMode,
              icon: const Icon(Icons.checklist),
              tooltip: 'تحديد متعدد',
            );
          }),
          Obx(() {
            if (controller.newOrdersCount.value > 0) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: controller.clearNewOrdersCount,
                    icon: const Icon(Icons.notifications_active),
                    tooltip: 'طلبات جديدة',
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${controller.newOrdersCount.value}',
                        style: const TextStyle(
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
            return const SizedBox.shrink();
          }),
          IconButton(
            onPressed: controller.testSound,
            icon: const Icon(Icons.volume_up),
            tooltip: 'اختبار الصوت',
          ),
          IconButton(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        if (!controller.selectionMode.value) {
          return const SizedBox.shrink();
        }
        final count = controller.selectedOrderIds.length;
        return OrderBulkSelectionBar(
          selectedCount: count,
          visibleCount: controller.filteredOrders.length,
          accentColor: _accent,
          onSelectAll: () {
            if (controller.selectedCount == controller.filteredOrders.length) {
              controller.clearSelectedOrders();
            } else {
              controller.selectAllVisible();
            }
          },
          onClearSelection: controller.clearSelectedOrders,
          onChangeStatus: () => OrderBulkSelectionBar.showBulkStatusDialog(
            count: controller.selectedCount,
            itemLabel: 'طلب زبون',
            accentColor: _accent,
            onConfirm: ({
              required int status,
              required String label,
              String? deliveryTime,
              int? deliveryDurationMinutes,
              DateTime? deliveryDeadlineAt,
            }) =>
                controller.updateSelectedOrdersStatus(
              newStatus: status,
              newOrderStatus: label,
              deliveryTime: deliveryTime,
              deliveryDurationMinutes: deliveryDurationMinutes,
              deliveryDeadlineAt: deliveryDeadlineAt,
            ),
          ),
          onDelete: () => OrderBulkSelectionBar.showBulkDeleteDialog(
            count: controller.selectedCount,
            itemLabel: 'طلب زبون',
            onConfirm: controller.deleteSelectedOrders,
          ),
        );
      }),
      body: Column(
        children: [
          _buildStatsBar(),
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              final selectionMode = controller.selectionMode.value;
              final selectedIds =
                  List<String>.from(controller.selectedOrderIds);
              final bulkWorking = controller.isBulkWorking.value;

              if (controller.isLoading.value &&
                  controller.filteredOrders.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: _accent),
                );
              }
              if (controller.errorMessage.value.isNotEmpty &&
                  controller.filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(controller.errorMessage.value),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.refresh,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }
              if (controller.filteredOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد طلبات زبائن',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'كل طلبات الزبائن تظهر هنا بدون قيد فرع',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: controller.refresh,
                    color: _accent,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = controller.filteredOrders[index];
                        return OrderCard(
                          order: order,
                          selectionMode: selectionMode,
                          isSelected: selectedIds.contains(order.id),
                          onToggleSelect: () =>
                              controller.toggleOrderSelection(order.id),
                          onViewDetails: () => Get.to(
                            () => OrderDetailsScreen(order: order),
                          ),
                          onUpdateStatus: () => _showStatusDialog(order),
                          onDelete: () => _showDeleteConfirmation(order),
                        );
                      },
                    ),
                  ),
                  if (bulkWorking)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(color: _accent),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _accent.withOpacity(0.85)],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _statTile(
                  'الإجمالي',
                  '${controller.stats['total'] ?? 0}',
                  Icons.shopping_bag,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  'تجهيز',
                  '${controller.stats['preparing'] ?? 0}',
                  Icons.restaurant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  'توصيل',
                  '${controller.stats['delivering'] ?? 0}',
                  Icons.delivery_dining,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statTile(
                  'مكتمل',
                  '${controller.stats['delivered'] ?? 0}',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _statTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: TextField(
        decoration: InputDecoration(
          hintText: 'بحث بالاسم أو الهاتف...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            onPressed: () => controller.searchOrders(''),
            icon: const Icon(Icons.clear),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: controller.searchOrders,
      ),
    );
  }

  void _showStatusDialog(OrderModel order) {
    Get.dialog(
      OrderStatusDialog(
        order: order,
        onUpdateStatus: controller.updateOrderStatus,
      ),
      barrierDismissible: true,
    );
  }

  void _showDeleteConfirmation(OrderModel order) {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف طلب هذا الزبون؟'),
        actions: [
          TextButton(
            onPressed: closeDashboardDialog,
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              closeDashboardDialog();
              controller.deleteOrder(order.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
