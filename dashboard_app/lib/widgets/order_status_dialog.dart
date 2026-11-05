import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/dashboard_dialog.dart';
import '../utils/delivery_duration_utils.dart';
import '../models/order_model.dart';
import '../controllers/order_controller.dart';

class OrderStatusDialog extends StatefulWidget {
  final OrderModel order;
  final Future<bool> Function(
    String orderId,
    int newStatus,
    String newOrderStatus, {
    String? deliveryTime,
    String? customerMessage,
    int? deliveryDurationMinutes,
    DateTime? deliveryDeadlineAt,
  })? onUpdateStatus;

  const OrderStatusDialog({
    super.key,
    required this.order,
    this.onUpdateStatus,
  });

  @override
  State<OrderStatusDialog> createState() => _OrderStatusDialogState();
}

class _OrderStatusDialogState extends State<OrderStatusDialog> {
  late int selectedStatus;
  final OrderController orderController = Get.find<OrderController>();
  bool _isUpdating = false;

  late int _selectedHours;
  late int _selectedMinutes; // 0, 15, 30, 45

  int get _totalMinutes =>
      DeliveryDurationUtils.clampMinutesRaw(_selectedHours * 60 + _selectedMinutes);

  int get _initialTotalMinutes {
    final existing = widget.order.deliveryDurationMinutes;
    if (existing != null && existing >= DeliveryDurationUtils.minMinutes) {
      return DeliveryDurationUtils.clampMinutesRaw(existing);
    }
    return DeliveryDurationUtils.minMinutes;
  }

  bool get _needsDeliveryDuration => selectedStatus == 1;

  bool get _canSubmit {
    if (_isUpdating) return false;
    if (_needsDeliveryDuration) {
      final durationChanged = _totalMinutes != _initialTotalMinutes;
      return selectedStatus != widget.order.status || durationChanged;
    }
    return selectedStatus != widget.order.status;
  }

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
    final initial = _initialTotalMinutes;
    _selectedHours = initial ~/ 60;
    _selectedMinutes = initial % 60;
    if (_selectedMinutes % 15 != 0) {
      _selectedMinutes = ((_selectedMinutes / 15).round() * 15) % 60;
    }
    _normalizeDurationSelection();
  }

  void _normalizeDurationSelection() {
    var total = _selectedHours * 60 + _selectedMinutes;
    total = DeliveryDurationUtils.clampMinutesRaw(total);
    if (total < DeliveryDurationUtils.minMinutes) {
      total = DeliveryDurationUtils.minMinutes;
    }
    if (_selectedHours == 48) {
      _selectedMinutes = 0;
      total = DeliveryDurationUtils.maxMinutes;
    }
    _selectedHours = total ~/ 60;
    _selectedMinutes = total % 60;
  }

  List<int> get _minuteOptions {
    if (_selectedHours == 0) return [15, 30, 45];
    if (_selectedHours == 48) return [0];
    return [0, 15, 30, 45];
  }

  List<int> get _hourOptions => List<int>.generate(49, (i) => i);

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
                Row(
                  children: [
                    Icon(Icons.update, color: Colors.blue[600], size: 24),
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
                      onPressed:
                          _isUpdating ? null : () => closeDashboardDialog(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 16),
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      Text(
                        'العميل: ${widget.order.name}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      Text(
                        'المبلغ: ${widget.order.formattedTotalAmount}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
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
                    border: Border.all(
                      color: _getCurrentStatusColor().withOpacity(0.3),
                    ),
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
                Text(
                  'اختر الحالة الجديدة:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
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
                                width:
                                    selectedStatus == status['value'] ? 2 : 1,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                    )),
                if (_needsDeliveryDuration) ...[
                  SizedBox(height: 20),
                  _buildDeliveryDurationField(),
                ],
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 120,
                      child: OutlinedButton(
                        onPressed:
                            _isUpdating ? null : () => closeDashboardDialog(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
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
                    SizedBox(
                      width: 140,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _updateOrderStatus : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canSubmit ? Colors.blue[600] : Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: _canSubmit ? 2 : 0,
                        ),
                        child: _isUpdating
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
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

  Widget _buildDeliveryDurationField() {
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
              Icon(Icons.timer_outlined, color: Colors.blue[700], size: 20),
              SizedBox(width: 8),
              Text(
                'وقت التوصيل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedHours,
                  decoration: InputDecoration(
                    labelText: 'الساعات',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _hourOptions
                      .map(
                        (h) => DropdownMenuItem<int>(
                          value: h,
                          child: Text('$h'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedHours = v;
                      if (!_minuteOptions.contains(_selectedMinutes)) {
                        _selectedMinutes = _minuteOptions.first;
                      }
                      _normalizeDurationSelection();
                    });
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _minuteOptions.contains(_selectedMinutes)
                      ? _selectedMinutes
                      : _minuteOptions.first,
                  decoration: InputDecoration(
                    labelText: 'الدقائق',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _minuteOptions
                      .map(
                        (m) => DropdownMenuItem<int>(
                          value: m,
                          child: Text('$m'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedMinutes = v;
                      _normalizeDurationSelection();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'المدة المختارة: ${DeliveryDurationUtils.formatArabic(_totalMinutes)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'من ربع ساعة إلى 48 ساعة (بخطوات 15 دقيقة). يبدأ العدّاد في تطبيق الزبون من لحظة التحديث.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
    if (_isUpdating) return;

    if (_needsDeliveryDuration) {
      final total = _totalMinutes;
      if (total < DeliveryDurationUtils.minMinutes ||
          total > DeliveryDurationUtils.maxMinutes) {
        Get.snackbar(
          'تنبيه',
          'اختر مدة توصيل من 15 دقيقة إلى 48 ساعة',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
    }

    setState(() => _isUpdating = true);

    try {
      final selectedOption =
          statusOptions.firstWhere((option) => option['value'] == selectedStatus);

      String? deliveryTime;
      int? deliveryDurationMinutes;
      DateTime? deliveryDeadlineAt;

      if (_needsDeliveryDuration) {
        deliveryDurationMinutes = _totalMinutes;
        deliveryDeadlineAt =
            DateTime.now().add(Duration(minutes: deliveryDurationMinutes));
        deliveryTime =
            DeliveryDurationUtils.formatArabic(deliveryDurationMinutes);
      }

      final success = widget.onUpdateStatus != null
          ? await widget.onUpdateStatus!(
              widget.order.id,
              selectedStatus,
              selectedOption['label'],
              deliveryTime: deliveryTime,
              deliveryDurationMinutes: deliveryDurationMinutes,
              deliveryDeadlineAt: deliveryDeadlineAt,
            )
          : await orderController.updateOrderStatus(
              widget.order.id,
              selectedStatus,
              selectedOption['label'],
              deliveryTime: deliveryTime,
              deliveryDurationMinutes: deliveryDurationMinutes,
              deliveryDeadlineAt: deliveryDeadlineAt,
            );

      if (!mounted) return;

      if (success) {
        closeDashboardDialog(afterFrame: true);
        Get.snackbar(
          'نجح',
          'تم تحديث حالة الطلب بنجاح',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        setState(() => _isUpdating = false);
        Get.snackbar(
          'خطأ',
          'فشل في تحديث حالة الطلب',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isUpdating = false);
      Get.snackbar(
        'خطأ',
        'فشل في تحديث حالة الطلب: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
