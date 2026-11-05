import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/payment_gateway_controller.dart';
import '../services/dnz_payment_service.dart';

class PaymentGatewayScreen extends StatelessWidget {
  PaymentGatewayScreen({super.key});

  final PaymentGatewayController controller =
      Get.put(PaymentGatewayController());

  static final _iqdFormat = NumberFormat('#,###', 'en');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بوابة الدفع'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildFormCard(),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.paymentUrl.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildResultCard();
          }),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: Colors.deepPurple.shade700, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'إنشاء رابط دفع عبر حساب DNZ Gateway (نفس حساب التطبيق) — المبلغ بالدينار العراقي',
              style: TextStyle(
                fontSize: 13,
                color: Colors.deepPurple.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller.amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ (دينار عراقي)',
                hintText: 'مثال: 25000',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم',
                hintText: 'اسم المنتج أو الزبون',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'الوصف',
                hintText: 'وصف عملية الدفع',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final loading = controller.isLoading.value;
              return SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : controller.createLink,
                  icon: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.link),
                  label: Text(
                    loading ? 'جاري الإنشاء...' : 'إنشاء رابط الدفع',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final amountText = controller.amountController.text.trim();
    final amount = int.tryParse(amountText.replaceAll(',', ''));
    final status = controller.paymentStatus.value;
    final statusColor = DnzPaymentService.isSuccessStatus(status)
        ? Colors.green
        : DnzPaymentService.isFailedStatus(status)
            ? Colors.red
            : Colors.orange;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'تم إنشاء الرابط',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.clearResult,
                  child: const Text('مسح'),
                ),
              ],
            ),
            const Divider(),
            if (amount != null)
              _infoRow('المبلغ', '${_iqdFormat.format(amount)} د.ع'),
            _infoRow('الاسم', controller.nameController.text.trim()),
            _infoRow('الوصف', controller.descriptionController.text.trim()),
            _infoRow('معرّف الدفع', controller.paymentId.value),
            Obx(() => _infoRow(
                  'الحالة',
                  controller.paymentStatus.value.isEmpty
                      ? '—'
                      : controller.paymentStatus.value,
                  valueColor: statusColor,
                )),
            const SizedBox(height: 8),
            SelectableText(
              controller.paymentUrl.value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.deepPurple.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.copyLink,
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: controller.openLink,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('فتح'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              final checking = controller.isCheckingStatus.value;
              return TextButton.icon(
                onPressed: checking ? null : controller.refreshStatus,
                icon: checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(checking ? 'جاري التحقق...' : 'تحديث حالة الدفع'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
