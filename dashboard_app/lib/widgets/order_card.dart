import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../utils/order_location_utils.dart';
import '../utils/whatsapp_launcher.dart';


class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onViewDetails;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelect;

  const OrderCard({
    super.key,
    required this.order,
    required this.onViewDetails,
    required this.onUpdateStatus,
    required this.onDelete,
    this.selectionMode = false,
    this.isSelected = false,
    this.onToggleSelect,
  });

  OrderLocationInfo get _locationInfo => orderLocationInfo(order);

  @override
  Widget build(BuildContext context) {
    final card = Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isSelected
            ? BorderSide(color: Colors.deepPurple, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة - معلومات الطلب الأساسية
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
              children: [
                if (selectionMode) ...[
                  // العرض فقط — الضغط يُعالَج من InkWell الخارجي لتفادي التبديل المزدوج
                  Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: isSelected ? Colors.deepPurple : Colors.grey[600],
                    size: 26,
                  ),
                  SizedBox(width: 4),
                ],
                // أيقونة الحالة
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getStatusIcon(),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                
                // معلومات الطلب
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رقم الطلب والحالة
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'طلب #${order.originalId}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              alignment: WrapAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    order.orderstatus,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (order.isPaidOnline)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.teal,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'دفع أونلاين',
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
                        ],
                      ),
                      SizedBox(height: 4),
                      
                      // اسم العميل
                      Text(
                        order.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      
                      // رقم الهاتف
                      InkWell(
                        onTap: () => WhatsAppLauncher.openChat(order.userPhone),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat, size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                order.userPhone.isNotEmpty
                                    ? order.userPhone
                                    : 'لا يوجد رقم',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: order.userPhone.isNotEmpty
                                      ? Colors.green.shade800
                                      : Colors.grey,
                                  decoration: order.userPhone.isNotEmpty
                                      ? TextDecoration.underline
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                // الموقع / تفاصيل الطلب
                if (_locationInfo.hasContent) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _locationInfo.cardPrimary,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_locationInfo.cardLandmark != null) ...[
                              SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.flag_outlined,
                                      size: 14, color: Colors.grey[500]),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _locationInfo.cardLandmark!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                ],
                
                // المنتجات
                Text(
                  'المنتجات (${order.items.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                
                // قائمة المنتجات
                ...order.items.map((item) => Container(
                  margin: EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.title} (${item.count}x)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Text(
                        '${item.totalPrice.toStringAsFixed(0)} د.ع',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                
                SizedBox(height: 12),
                
                // المبلغ الإجمالي وطريقة الدفع
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'المبلغ الإجمالي',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          order.formattedTotalAmount,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'طريقة الدفع',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          order.paymentMethod,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: order.isPaidOnline
                                ? Colors.teal[700]
                                : Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // التاريخ والوقت
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      order.formattedCreatedAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                
                // ملاحظات
                if (order.note != null && order.note!.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.orange[700]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // أزرار الإجراءات
          if (!selectionMode)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                // زر عرض التفاصيل
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onViewDetails,
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('التفاصيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                
                // زر تحديث الحالة
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onUpdateStatus,
                    icon: Icon(Icons.update, size: 16),
                    label: Text('تحديث'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                
                // زر الحذف
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete, color: Colors.red[600]),
                  tooltip: 'حذف الطلب',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!selectionMode) return card;

    return InkWell(
      onTap: onToggleSelect,
      borderRadius: BorderRadius.circular(15),
      child: card,
    );
  }

  Color _getStatusColor() {
    switch (order.status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.purple;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (order.status) {
      case 0:
        return Icons.pending;
      case 1:
        return Icons.restaurant;
      case 2:
        return Icons.delivery_dining;
      case 3:
        return Icons.check_circle;
      case 4:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
