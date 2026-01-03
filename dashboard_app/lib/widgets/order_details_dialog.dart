import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderDetailsDialog extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsDialog({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // رأس الدايلوج
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'تفاصيل الطلب #${order.originalId}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // محتوى الدايلوج
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات العميل
                    _buildSection(
                      title: 'معلومات العميل',
                      icon: Icons.person,
                      children: [
                        _buildInfoRow('الاسم', order.name),
                        _buildInfoRow('رقم الهاتف', order.userPhone),
                        if (order.address.isNotEmpty)
                          _buildInfoRow('العنوان', '${order.address}, ${order.city}'),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // حالة الطلب
                    _buildSection(
                      title: 'حالة الطلب',
                      icon: Icons.info,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getStatusColor().withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(),
                                color: _getStatusColor(),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                order.orderstatus,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // المنتجات
                    _buildSection(
                      title: 'المنتجات (${order.items.length})',
                      icon: Icons.shopping_cart,
                      children: [
                        ...order.items.map((item) => Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              // صورة المنتج
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[200],
                                ),
                                child: item.image.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: ImageUtils.getCorrectImageUrl(
                                            item.image,
                                            'product',
                                            item.id,
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
                                            size: 30,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[400],
                                        size: 30,
                                      ),
                              ),
                              SizedBox(width: 12),
                              
                              // تفاصيل المنتج
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'الكمية: ${item.count}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'السعر: ${item.price.toStringAsFixed(0)} د.ع',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // السعر الإجمالي
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'الإجمالي',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${item.totalPrice.toStringAsFixed(0)} د.ع',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                    
                    SizedBox(height: 20),
                    
                    // معلومات الدفع والتوصيل
                    _buildSection(
                      title: 'معلومات الدفع والتوصيل',
                      icon: Icons.payment,
                      children: [
                        _buildInfoRow('طريقة الدفع', 'نقدي'), // يمكن إضافة paymentMethod لاحقاً إذا كان موجوداً في البيانات
                        _buildInfoRow('المبلغ الإجمالي', order.formattedTotalAmount),
                        _buildInfoRow('تاريخ الطلب', order.formattedCreatedAt),
                        if (order.updatedAt != null)
                          _buildInfoRow('آخر تحديث', _formatDateTime(order.updatedAt!)),
                      ],
                    ),
                    
                    // الموقع (إذا كان متوفراً)
                    if (order.near.isNotEmpty) ...[
                      SizedBox(height: 20),
                      _buildSection(
                        title: 'موقع التوصيل',
                        icon: Icons.location_on,
                        children: [
                          _buildInfoRow('الموقع', order.near),
                          if (order.nearpoint.isNotEmpty)
                            _buildInfoRow('نقطة قريبة', order.nearpoint),
                        ],
                      ),
                    ],
                    
                    // الملاحظات
                    if (order.note != null && order.note!.isNotEmpty) ...[
                      SizedBox(height: 20),
                      _buildSection(
                        title: 'ملاحظات',
                        icon: Icons.note,
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Text(
                              order.note!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue[600], size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
