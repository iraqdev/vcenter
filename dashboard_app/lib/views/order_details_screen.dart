import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order_model.dart';
import '../utils/image_utils.dart';
import '../widgets/order_status_dialog.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  SizedBox(height: 16),
                  _buildCustomerSection(),
                  SizedBox(height: 16),
                  _buildDeliverySection(),
                  SizedBox(height: 16),
                  _buildProductsSection(),
                  SizedBox(height: 16),
                  _buildPaymentSection(),
                  if (order.note != null && order.note!.isNotEmpty) ...[
                    SizedBox(height: 16),
                    _buildNotesSection(),
                  ],
                  SizedBox(height: 24),
                  _buildActionButton(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final statusColor = _getStatusColor();
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        ),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Get.back();
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              order.formattedCreatedAt,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              'طلب #${order.originalId}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                statusColor,
                statusColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SizedBox.expand(),
        ),
      ),
      backgroundColor: statusColor,
    );
  }

  Widget _buildStatusCard() {
    final statusColor = _getStatusColor();
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getStatusIcon(), color: statusColor, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الطلب',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  order.orderstatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (order.deliveryTime != null && order.deliveryTime!.isNotEmpty) ...[
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Text(
                        'وقت التوصيل: ${order.deliveryTime}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return _buildSectionCard(
      icon: Icons.person_outline,
      iconColor: Colors.blue,
      title: 'معلومات العميل',
      children: [
        _buildInfoRow(Icons.badge_outlined, 'الاسم', order.name),
        _buildInfoRow(Icons.phone_android, 'رقم الهاتف', order.userPhone),
        if (order.address.isNotEmpty)
          _buildInfoRow(Icons.location_on_outlined, 'العنوان', '${order.address}، ${order.city}'),
        if (order.closestBranch != null && order.closestBranch!.isNotEmpty)
          _buildInfoRow(Icons.store, 'الفرع الأقرب', order.closestBranch!),
      ],
    );
  }

  Widget _buildDeliverySection() {
    if (order.near.isEmpty && order.nearpoint.isEmpty) return SizedBox.shrink();
    return _buildSectionCard(
      icon: Icons.local_shipping_outlined,
      iconColor: Colors.orange,
      title: 'موقع التوصيل',
      children: [
        if (order.near.isNotEmpty) _buildInfoRow(Icons.place, 'الموقع', order.near),
        if (order.nearpoint.isNotEmpty) _buildInfoRow(Icons.flag, 'نقطة قريبة', order.nearpoint),
      ],
    );
  }

  Widget _buildProductsSection() {
    return _buildSectionCard(
      icon: Icons.shopping_bag_outlined,
      iconColor: Colors.green,
      title: 'المنتجات (${order.items.length})',
      children: order.items.map((item) => _buildProductItem(item)).toList(),
    );
  }

  Widget _buildProductItem(OrderItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ImageUtils.getCorrectImageUrl(item.image, 'product', item.id),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400]),
                      ),
                      errorWidget: (_, __, ___) => Icon(Icons.image_not_supported, color: Colors.grey[400]),
                    )
                  : Icon(Icons.inventory_2_outlined, color: Colors.grey[400], size: 32),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    _buildChip('×${item.count}', Colors.grey[600]!),
                    if (item.color.isNotEmpty) ...[
                      SizedBox(width: 6),
                      _buildChip(item.color, Colors.grey[600]!),
                    ],
                    if (item.size.isNotEmpty) ...[
                      SizedBox(width: 6),
                      _buildChip(item.size, Colors.grey[600]!),
                    ],
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} د.ع / قطعة',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildPaymentSection() {
    return _buildSectionCard(
      icon: Icons.payment_outlined,
      iconColor: Colors.purple,
      title: 'معلومات الدفع',
      children: [
        _buildInfoRow(Icons.monetization_on_outlined, 'المبلغ الإجمالي', order.formattedTotalAmount),
        _buildInfoRow(Icons.calendar_today_outlined, 'تاريخ الطلب', order.formattedCreatedAt),
        if (order.updatedAt != null)
          _buildInfoRow(Icons.update, 'آخر تحديث', _formatDateTime(order.updatedAt!)),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildSectionCard(
      icon: Icons.note_alt_outlined,
      iconColor: Colors.amber,
      title: 'ملاحظات',
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Text(
            order.note!,
            style: TextStyle(fontSize: 14, color: Colors.amber[900], height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
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

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Get.dialog(
            OrderStatusDialog(order: order),
            barrierDismissible: true,
          );
        },
        icon: Icon(Icons.edit_outlined, size: 22),
        label: Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text('تحديث حالة الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.deepPurple.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  Color _getStatusColor() {
    switch (order.status) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: return Colors.purple;
      case 3: return Colors.green;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (order.status) {
      case 0: return Icons.pending;
      case 1: return Icons.delivery_dining;
      case 2: return Icons.check_circle;
      case 3: return Icons.check_circle;
      case 4: return Icons.cancel;
      default: return Icons.help;
    }
  }
}
