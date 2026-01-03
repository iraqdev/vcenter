import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/order_model.dart';
import '../controllers/order_controller.dart';

class OrderStatusDialog extends StatefulWidget {
  final OrderModel order;

  const OrderStatusDialog({
    super.key,
    required this.order,
  });

  @override
  State<OrderStatusDialog> createState() => _OrderStatusDialogState();
}

class _OrderStatusDialogState extends State<OrderStatusDialog> {
  late int selectedStatus;
  final OrderController orderController = Get.find<OrderController>();
  final TextEditingController deliveryTimeController = TextEditingController();

  final List<Map<String, dynamic>> statusOptions = [
    {
      'value': 0,
      'label': 'جاري التجهيز',
      'icon': Icons.access_time,
      'color': Colors.orange,
      'description': 'الطلب قيد التجهيز',
    },
    {
      'value': 1,
      'label': 'جاري التوصيل',
      'icon': Icons.delivery_dining,
      'color': Colors.blue,
      'description': 'الطلب في الطريق للعميل',
    },
    {
      'value': 2,
      'label': 'تم الاستلام',
      'icon': Icons.check_circle,
      'color': Colors.green,
      'description': 'تم استلام الطلب بنجاح',
    },
    {
      'value': 3,
      'label': 'ملغي',
      'icon': Icons.cancel,
      'color': Colors.red,
      'description': 'تم إلغاء الطلب',
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.order.status;
    // تهيئة وقت التوصيل من الطلب الحالي أو فارغ
    deliveryTimeController.text = widget.order.deliveryTime ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // العنوان
            Row(
              children: [
                Icon(
                  Icons.update,
                  color: Colors.blue[600],
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تحديث حالة الطلب',
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
            
            SizedBox(height: 16),
            
            // معلومات الطلب
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'معلومات الطلب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'رقم الطلب: #${widget.order.id.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'العميل: ${widget.order.name}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'المبلغ: ${widget.order.formattedTotalAmount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // الحالة الحالية
            Text(
              'الحالة الحالية:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getCurrentStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getCurrentStatusColor().withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCurrentStatusIcon(),
                    color: _getCurrentStatusColor(),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    _getCurrentStatusLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getCurrentStatusColor(),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // اختيار الحالة الجديدة
            Text(
              'اختر الحالة الجديدة:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            
            // قائمة الحالات
            ...statusOptions.map((status) => Container(
              margin: EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedStatus = status['value'] as int;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedStatus == status['value']
                          ? status['color'].withOpacity(0.1)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedStatus == status['value']
                            ? status['color']
                            : Colors.grey[300]!,
                        width: selectedStatus == status['value'] ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: status['color'],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            status['icon'],
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status['label'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                status['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedStatus == status['value'])
                          Icon(
                            Icons.check_circle,
                            color: status['color'],
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            )).toList(),
            
            SizedBox(height: 20),
            
            // حقل وقت التوصيل (يظهر فقط عند اختيار "جاري التوصيل")
            if (selectedStatus == 1) _buildDeliveryTimeField(),
            
            SizedBox(height: 24),
            
            // أزرار الإجراءات
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // زر الإلغاء
                SizedBox(
                  width: 120,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                    ),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // زر التحديث
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: selectedStatus != widget.order.status
                        ? _updateOrderStatus
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedStatus != widget.order.status 
                          ? Colors.blue[600] 
                          : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: selectedStatus != widget.order.status ? 2 : 0,
                    ),
                    child: Text(
                      'تحديث الحالة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildDeliveryTimeField() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.blue[600],
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'وقت التوصيل المتوقع',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          TextField(
            controller: deliveryTimeController,
            decoration: InputDecoration(
              hintText: 'مثال: 20-30 دقيقة',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            'سيظهر هذا الوقت للمستخدم في شاشة تتبع الطلب',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCurrentStatusColor() {
    final currentStatus = statusOptions.firstWhere(
      (status) => status['value'] == widget.order.status,
      orElse: () => statusOptions.first,
    );
    return currentStatus['color'];
  }

  IconData _getCurrentStatusIcon() {
    final currentStatus = statusOptions.firstWhere(
      (status) => status['value'] == widget.order.status,
      orElse: () => statusOptions.first,
    );
    return currentStatus['icon'];
  }

  String _getCurrentStatusLabel() {
    final currentStatus = statusOptions.firstWhere(
      (status) => status['value'] == widget.order.status,
      orElse: () => statusOptions.first,
    );
    return currentStatus['label'];
  }

  void _updateOrderStatus() async {
    try {
      print('OrderStatusDialog: بدء تحديث حالة الطلب');
      print('OrderStatusDialog: معرف الطلب: ${widget.order.id}');
      print('OrderStatusDialog: الحالة المختارة: $selectedStatus');
      
      final selectedOption = statusOptions.firstWhere((option) => option['value'] == selectedStatus);
      print('OrderStatusDialog: الخيار المختار: ${selectedOption['label']}');
      
      // إضافة وقت التوصيل إذا كان الحالة "جاري التوصيل"
      String? deliveryTime;
      if (selectedStatus == 1) {
        deliveryTime = deliveryTimeController.text.trim();
        if (deliveryTime.isEmpty) {
          Get.snackbar(
            'خطأ',
            'الرجاء إدخال وقت التوصيل المتوقع',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }
      
      final success = await orderController.updateOrderStatus(
        widget.order.id,
        selectedStatus,
        selectedOption['label'],
        deliveryTime: deliveryTime,
      );
      
      print('OrderStatusDialog: نتيجة التحديث: $success');
      
      if (success) {
        Get.back();
        Get.snackbar(
          'نجح',
          'تم تحديث حالة الطلب بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'خطأ',
          'فشل في تحديث حالة الطلب',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('OrderStatusDialog: خطأ في تحديث حالة الطلب: $e');
      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة الطلب: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
