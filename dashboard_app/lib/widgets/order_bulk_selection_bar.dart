import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/delivery_duration_utils.dart';

/// شريط سفلي لتغيير حالة الطلبات المحددة أو حذفها.
class OrderBulkSelectionBar extends StatelessWidget {
  final int selectedCount;
  final int visibleCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onDelete;
  final VoidCallback? onChangeStatus;
  final Color accentColor;

  const OrderBulkSelectionBar({
    super.key,
    required this.selectedCount,
    required this.visibleCount,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onDelete,
    this.onChangeStatus,
    this.accentColor = Colors.deepPurple,
  });

  static const List<Map<String, dynamic>> statusOptions = [
    {
      'value': 0,
      'label': 'جاري التجهيز',
      'icon': Icons.access_time,
      'color': Colors.orange,
    },
    {
      'value': 1,
      'label': 'جاري التوصيل',
      'icon': Icons.delivery_dining,
      'color': Colors.blue,
    },
    {
      'value': 2,
      'label': 'تم الاستلام',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    {
      'value': 3,
      'label': 'ملغي',
      'icon': Icons.cancel,
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '$selectedCount محدد',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: visibleCount > 0 ? onSelectAll : null,
                    child: Text(
                      selectedCount == visibleCount && visibleCount > 0
                          ? 'إلغاء الكل'
                          : 'تحديد الكل ($visibleCount)',
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: selectedCount > 0 ? onClearSelection : null,
                    child: const Text('مسح'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedCount > 0 ? onChangeStatus : null,
                      icon: const Icon(Icons.sync_alt, size: 18),
                      label: Text('تغيير الحالة ($selectedCount)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: selectedCount > 0 ? onDelete : null,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text('حذف ($selectedCount)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showBulkDeleteDialog({
    required int count,
    required Future<void> Function() onConfirm,
    String itemLabel = 'طلب',
  }) {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف الجماعي'),
        content: Text(
          'هل أنت متأكد من حذف $count $itemLabel؟\n\nهذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  static void showBulkStatusDialog({
    required int count,
    required Future<void> Function({
      required int status,
      required String label,
      String? deliveryTime,
      int? deliveryDurationMinutes,
      DateTime? deliveryDeadlineAt,
    }) onConfirm,
    Color accentColor = Colors.deepPurple,
    String itemLabel = 'طلب',
  }) {
    Get.dialog(
      AlertDialog(
        title: Text('تغيير حالة $count $itemLabel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.map((option) {
            final color = option['color'] as Color;
            final status = option['value'] as int;
            final label = option['label'] as String;
            return ListTile(
              leading: Icon(option['icon'] as IconData, color: color),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              onTap: () async {
                Get.back();
                if (status == 1) {
                  final duration = await showBulkDeliveryDurationDialog(
                    count: count,
                    accentColor: accentColor,
                  );
                  if (duration == null) return;
                  final deadline =
                      DateTime.now().add(Duration(minutes: duration));
                  await onConfirm(
                    status: status,
                    label: label,
                    deliveryTime: DeliveryDurationUtils.formatArabic(duration),
                    deliveryDurationMinutes: duration,
                    deliveryDeadlineAt: deadline,
                  );
                } else {
                  await onConfirm(status: status, label: label);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  /// اختيار مدة توصيل واحدة تُطبَّق على كل الطلبات المحددة.
  static Future<int?> showBulkDeliveryDurationDialog({
    required int count,
    Color accentColor = Colors.deepPurple,
  }) {
    return Get.dialog<int>(
      _BulkDeliveryDurationDialog(
        count: count,
        accentColor: accentColor,
      ),
      barrierDismissible: true,
    );
  }
}

class _BulkDeliveryDurationDialog extends StatefulWidget {
  final int count;
  final Color accentColor;

  const _BulkDeliveryDurationDialog({
    required this.count,
    required this.accentColor,
  });

  @override
  State<_BulkDeliveryDurationDialog> createState() =>
      _BulkDeliveryDurationDialogState();
}

class _BulkDeliveryDurationDialogState
    extends State<_BulkDeliveryDurationDialog> {
  int _selectedHours = 0;
  int _selectedMinutes = 15;

  int get _totalMinutes => _selectedHours * 60 + _selectedMinutes;

  List<int> get _minuteOptions {
    if (_selectedHours == 0) return [15, 30, 45];
    if (_selectedHours == 48) return [0];
    return [0, 15, 30, 45];
  }

  void _normalize() {
    var total = _totalMinutes;
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
    if (!_minuteOptions.contains(_selectedMinutes)) {
      _selectedMinutes = _minuteOptions.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('مدة التوصيل'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'اختر مدة توصيل واحدة لـ ${widget.count} طلب',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedHours,
                  decoration: const InputDecoration(
                    labelText: 'ساعات',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: List.generate(49, (i) => i)
                      .map((h) => DropdownMenuItem(value: h, child: Text('$h')))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedHours = v;
                      _normalize();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedMinutes,
                  decoration: const InputDecoration(
                    labelText: 'دقائق',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _minuteOptions
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _selectedMinutes = v;
                      _normalize();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'المدة: ${DeliveryDurationUtils.formatArabic(_totalMinutes)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.accentColor,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            final total =
                DeliveryDurationUtils.clampMinutes(_totalMinutes);
            Get.back(result: total);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.accentColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('تطبيق على الكل'),
        ),
      ],
    );
  }
}
