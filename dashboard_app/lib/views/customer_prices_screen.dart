import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/branch_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../utils/image_utils.dart';

/// شاشة أسعار منتجات الزبائن — الافتراضي: سعر المحل + 4000،
/// وعند التعديل يُحفظ السعر كما هو بدون إضافة 4000.
class CustomerPricesScreen extends StatefulWidget {
  const CustomerPricesScreen({super.key});

  @override
  State<CustomerPricesScreen> createState() => _CustomerPricesScreenState();
}

class _CustomerPricesScreenState extends State<CustomerPricesScreen> {
  final ProductController productController = Get.find<ProductController>();
  final BranchController branchController = Get.find<BranchController>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchMode = false;
  static final _fmt = NumberFormat('#,###', 'en');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        productController.searchProducts('');
      }
    });
    if (_isSearchMode) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  Future<void> _editCustomerPrice(ProductModel product) async {
    final controller = TextEditingController(
      text: product.effectiveCustomerPrice.toString(),
    );
    String? localError;

    final result = await Get.dialog<int?>(
      StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('سعر الزبون'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'سعر المحل: ${_fmt.format(product.price)} د.ع',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                Text(
                  'الافتراضي للزبون: ${_fmt.format(product.price + 4000)} د.ع',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                if (product.hasCustomCustomerPrice)
                  Text(
                    'سعر مخصص حالياً (بدون +4000)',
                    style: TextStyle(color: Colors.orange[800], fontSize: 12),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'سعر الزبون (د.ع)',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  onChanged: (_) {
                    if (localError != null) {
                      setDialogState(() => localError = null);
                    }
                  },
                ),
                if (localError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    localError!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (product.hasCustomCustomerPrice)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(-1),
                  child: const Text('إعادة للافتراضي'),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final v = int.tryParse(controller.text.trim());
                  if (v == null || v < 0) {
                    setDialogState(() => localError = 'أدخل سعراً صحيحاً');
                    return;
                  }
                  Navigator.of(dialogContext).pop(v);
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );

    controller.dispose();
    if (result == null) return;

    final ok = await productController.updateCustomerPrice(
      product.id,
      result == -1 ? null : result,
    );
    if (ok) {
      Get.snackbar(
        'تم',
        result == -1
            ? 'تمت إعادة السعر الافتراضي (+4000)'
            : 'تم حفظ سعر الزبون كما أدخلته',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'خطأ',
        'فشل حفظ سعر الزبون. حاول مرة أخرى',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: productController.searchProducts,
              )
            : const Text('أسعار منتجات الزبائن'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_isSearchMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleSearch,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearch,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                productController.fetchProducts(
                  branch: branchController.selectedBranch.value,
                );
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.deepPurple.shade50,
            child: Text(
              'الافتراضي: سعر المحل + 4000 د.ع — عند تعديل السعر يُحفظ كما هو للزبون فقط بدون إضافة 4000',
              style: TextStyle(fontSize: 12, color: Colors.deepPurple.shade800),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (productController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = productController.filteredProducts;
              if (list.isEmpty) {
                return const Center(child: Text('لا توجد منتجات'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final product = list[index];
                  return _buildRow(product);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(ProductModel product) {
    final imageUrl = ImageUtils.getCorrectImageUrl(
      product.mainImage,
      'product',
      product.originalId ?? 0,
    );

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: imageUrl.isEmpty
                ? Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image),
                  ),
          ),
        ),
        title: Text(
          product.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سعر المحل: ${_fmt.format(product.price)} د.ع',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'سعر الزبون: ${_fmt.format(product.effectiveCustomerPrice)} د.ع',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: product.hasCustomCustomerPrice
                          ? Colors.orange[800]
                          : Colors.deepPurple,
                    ),
                  ),
                  if (product.hasCustomCustomerPrice) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'مخصص',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.deepPurple),
          tooltip: 'تعديل سعر الزبون',
          onPressed: () => _editCustomerPrice(product),
        ),
        onTap: () => _editCustomerPrice(product),
      ),
    );
  }
}
