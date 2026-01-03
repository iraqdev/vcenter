import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../widgets/notification_card.dart';
import '../widgets/send_notification_dialog.dart';

class NotificationsManagementScreen extends StatelessWidget {
  NotificationsManagementScreen({super.key});

  final NotificationController notificationController = Get.find<NotificationController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة الإشعارات'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => notificationController.refresh(),
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

          // قائمة الإشعارات
          Expanded(
            child: Obx(() {
              if (notificationController.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepPurple,
                  ),
                );
              }

              if (notificationController.errorMessage.value.isNotEmpty) {
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
                        notificationController.errorMessage.value,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => notificationController.fetchNotifications(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                );
              }

              if (notificationController.filteredNotifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد إشعارات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'لم يتم العثور على أي إشعارات',
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
                onRefresh: () => notificationController.refresh(),
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: notificationController.filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = notificationController.filteredNotifications[index];
                    return NotificationCard(
                      notification: notification,
                      onViewDetails: () => _showNotificationDetails(notification),
                      onDelete: () => _showDeleteConfirmation(notification),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSendNotificationDialog(),
        icon: Icon(Icons.add),
        label: Text('إرسال إشعار'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatsBar() {
    return Obx(() {
      final stats = notificationController.stats;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('إجمالي', stats['total'] ?? 0, Icons.notifications),
            _buildStatItem('مرسلة', stats['sent'] ?? 0, Icons.check_circle),
            _buildStatItem('فاشلة', stats['failed'] ?? 0, Icons.error),
            _buildStatItem('مجدولة', stats['scheduled'] ?? 0, Icons.schedule),
          ],
        ),
      );
    });
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // شريط البحث
          TextField(
            decoration: InputDecoration(
              labelText: 'البحث في الإشعارات',
              hintText: 'العنوان، الرسالة، النوع...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => notificationController.searchNotifications(value),
          ),
          SizedBox(height: 16),

          // فلاتر سريعة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', 'all', 'type'),
                SizedBox(width: 8),
                _buildFilterChip('جميع المستخدمين', 'all_users', 'type'),
                SizedBox(width: 8),
                _buildFilterChip('مستخدم محدد', 'specific', 'type'),
                SizedBox(width: 8),
                _buildFilterChip('عروض', 'offer', 'type'),
                SizedBox(width: 8),
                _buildFilterChip('ترويج', 'promotion', 'type'),
              ],
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', 'all', 'status'),
                SizedBox(width: 8),
                _buildFilterChip('مرسلة', 'sent', 'status'),
                SizedBox(width: 8),
                _buildFilterChip('فاشلة', 'failed', 'status'),
                SizedBox(width: 8),
                _buildFilterChip('مجدولة', 'scheduled', 'status'),
                SizedBox(width: 8),
                _buildFilterChip('مسودة', 'draft', 'status'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.black87),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, String filterType) {
    return Obx(() {
      bool isSelected = false;
      if (filterType == 'type') {
        isSelected = notificationController.selectedType.value == value;
      } else if (filterType == 'status') {
        isSelected = notificationController.selectedStatus.value == value;
      }

      return FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            if (filterType == 'type') {
              notificationController.filterByType(value);
            } else if (filterType == 'status') {
              notificationController.filterByStatus(value);
            }
          }
        },
        selectedColor: Colors.deepPurple.withOpacity(0.2),
        checkmarkColor: Colors.deepPurple,
      );
    });
  }

  void _showNotificationDetails(NotificationModel notification) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تفاصيل الإشعار',
          style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('العنوان', notification.title),
              _buildDetailRow('الرسالة', notification.message),
              _buildDetailRow('النوع', notification.typeDisplayName),
              _buildDetailRow('الحالة', notification.statusDisplayName),
              if (notification.targetPhone != null)
                _buildDetailRow('رقم الهاتف المستهدف', notification.targetPhone!),
              _buildDetailRow('تاريخ الإنشاء', notification.formattedCreatedAt),
              _buildDetailRow('تاريخ الإرسال المجدول', notification.formattedScheduledAt),
              _buildDetailRow('عدد المرسل', notification.sentCount.toString()),
              _buildDetailRow('عدد الفاشل', notification.failedCount.toString()),
              if (notification.errorMessage != null)
                _buildDetailRow('رسالة الخطأ', notification.errorMessage!),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(NotificationModel notification) {
    Get.dialog(
      AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد أنك تريد حذف هذا الإشعار؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await notificationController.deleteNotification(notification.id);
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

  void _showSendNotificationDialog() {
    Get.dialog(SendNotificationDialog());
  }

}
