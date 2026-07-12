import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:get/get.dart';
import 'package:ecommerce/Services/order_rating_service.dart';
import 'package:ecommerce/main.dart';

/// يعيد `'yes'` أو `'no'` عند الإغلاق.
class OrderRatingDialog extends StatefulWidget {
  final int orderOriginalId;
  final String? closestBranch;

  const OrderRatingDialog({
    super.key,
    required this.orderOriginalId,
    this.closestBranch,
  });

  @override
  State<OrderRatingDialog> createState() => _OrderRatingDialogState();
}

class _OrderRatingDialogState extends State<OrderRatingDialog> {
  double _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _close(String result) {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(result);
  }

  Future<void> _onYes() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final userName = sharedPreferences?.getString('name') ?? '';
    final ok = await OrderRatingService.submitRating(
      orderOriginalId: widget.orderOriginalId,
      rating: _rating.round(),
      comment: _commentController.text,
      userName: userName,
      closestBranch: widget.closestBranch,
      markDelivered: true,
    );

    if (!mounted) return;

    if (ok) {
      _close('yes');
      Get.snackbar(
        'شكراً لك',
        'تم حفظ تقييمك بنجاح',
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      setState(() => _isSubmitting = false);
      Get.snackbar(
        'خطأ',
        'تعذر حفظ التقييم، حاول مرة أخرى',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
    }
  }

  void _onNo() {
    if (_isSubmitting) return;
    _close('no');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delivery_dining, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 12),
            const Text(
              'هل وصلك الطلب؟',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'قيّم الخدمة ثم اختر نعم أو لا',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 36,
              unratedColor: Colors.grey.shade300,
              itemBuilder: (_, __) => Icon(
                Icons.star_rounded,
                color: Colors.amber.shade600,
              ),
              onRatingUpdate: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'ملاحظة (اختياري)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _onNo,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'لا',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onYes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'نعم',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
