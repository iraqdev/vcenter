import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onViewDetails;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onViewDetails,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة (العنوان والحالة)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notification.statusDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // محتوى البطاقة
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // الرسالة
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),

                // معلومات الإشعار
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      notification.typeDisplayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      notification.formattedCreatedAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // المستخدم المستهدف
                if (notification.isForSpecificUser) ...[
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        'مستخدم محدد',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (notification.targetPhone != null) ...[
                        SizedBox(width: 8),
                        Text(
                          '(${notification.targetPhone})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 8),
                ] else ...[
                  Row(
                    children: [
                      Icon(Icons.group, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        'جميع المستخدمين',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],

                // إحصائيات الإرسال
                if (notification.isSent || notification.isFailed) ...[
                  Row(
                    children: [
                      Icon(Icons.send, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Text(
                        'مرسل: ${notification.sentCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 16),
                      if (notification.failedCount > 0) ...[
                        Icon(Icons.error, size: 16, color: Colors.red[600]),
                        SizedBox(width: 8),
                        Text(
                          'فاشل: ${notification.failedCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 12),
                ],

                // رابط العمل
                if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 16, color: Colors.blue[700]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notification.actionUrl!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                // رسالة الخطأ
                if (notification.errorMessage != null && notification.errorMessage!.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notification.errorMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                // أزرار الإجراءات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onViewDetails,
                        icon: Icon(Icons.info_outline, size: 18),
                        label: Text('التفاصيل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete, size: 18),
                        label: Text('حذف'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (notification.status) {
      case 'sent':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'scheduled':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
