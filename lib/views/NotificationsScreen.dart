import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/NotificationController.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController = Get.put(NotificationController());

    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Obx(() {
            if (notificationController.unreadCount.value > 0) {
              return TextButton(
                onPressed: () {
                  notificationController.markAllAsRead();
                  Get.snackbar(
                    'تم',
                    'تم تمييز جميع الإشعارات كمقروءة',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                child: Text(
                  'تمييز الكل كمقروء',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (notificationController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
          );
        }

        if (notificationController.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 20),
                Text(
                  'لا توجد إشعارات',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'ستظهر الإشعارات هنا عند استلامها',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    notificationController.refreshNotifications();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('تحديث الإشعارات'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: notificationController.notifications.length,
          itemBuilder: (context, index) {
            final notification = notificationController.notifications[index];
            final isRead = notification['isRead'] as bool;
            final timestamp = notification['timestamp'] as DateTime;

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: isRead ? 1 : 3,
              color: isRead ? Colors.grey[50] : Colors.white,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isRead ? Colors.grey[300] : Colors.deepPurple,
                  child: Icon(
                    Icons.notifications,
                    color: isRead ? Colors.grey[600] : Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  notification['title'] ?? 'إشعار',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: isRead ? Colors.grey[600] : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      notification['body'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                    SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'mark_read') {
                          notificationController.markAsRead(notification['id']);
                        } else if (value == 'delete') {
                          notificationController.deleteNotification(notification['id']);
                        }
                      },
                      itemBuilder: (context) => [
                        if (!isRead)
                          PopupMenuItem(
                            value: 'mark_read',
                            child: Row(
                              children: [
                                Icon(Icons.mark_email_read, size: 20),
                                SizedBox(width: 8),
                                Text('تمييز كمقروء'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('حذف', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  if (!isRead) {
                    notificationController.markAsRead(notification['id']);
                  }
                },
              ),
            );
          },
        );
      }),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} يوم';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else {
      return 'الآن';
    }
  }
}
