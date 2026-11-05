import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/product_linking_controller.dart';
import '../models/pos_item_model.dart';
import '../models/product_model.dart';

class ProductLinkingScreen extends StatelessWidget {
  const ProductLinkingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductLinkingController());

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ربط منتجات التطبيق مع سطح المكتب'),
          actions: [
            IconButton(
              onPressed: controller.loadData,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildTopBar(controller),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildAppPanel(controller)),
                          const VerticalDivider(width: 1),
                          Expanded(child: _buildPosPanel(controller)),
                        ],
                      );
                    }
                    return DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'منتجات التطبيق'),
                              Tab(text: 'مواد سطح المكتب'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildAppPanel(controller),
                                _buildPosPanel(controller),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
        bottomNavigationBar: Obx(() => _buildLinkBar(controller)),
      ),
    );
  }

  Widget _buildTopBar(ProductLinkingController controller) {
    final sync = controller.lastPosSync.value;
    final syncText = sync == null
        ? 'لم تُزامَن مواد سطح المكتب بعد — شغّل سكربت المزامنة على جهاز POS'
        : 'آخر مزامنة POS: ${DateFormat('yyyy/MM/dd HH:mm').format(sync)} • ${controller.posItems.length} مادة';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.deepPurple.withOpacity(0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر منتجاً من التطبيق ومادة من سطح المكتب ثم اضغط «حفظ الربط».',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(syncText, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          if (controller.errorMessage.value.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              controller.errorMessage.value,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppPanel(ProductLinkingController controller) {
    return _buildPanel(
      title: 'منتجات التطبيق',
      icon: Icons.phone_android,
      color: Colors.deepPurple,
      searchController: controller.appSearchQuery,
      hint: 'بحث بالاسم أو الوصف أو كود POS المربوط...',
      child: Obx(() {
        final items = controller.filteredAppProducts;
        if (items.isEmpty) {
          return const Center(child: Text('لا توجد منتجات'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) => _appProductTile(controller, items[index]),
        );
      }),
    );
  }

  Widget _buildPosPanel(ProductLinkingController controller) {
    return _buildPanel(
      title: 'مواد برنامج سطح المكتب (DNZTeamPOS)',
      icon: Icons.desktop_windows,
      color: Colors.teal,
      searchController: controller.posSearchQuery,
      hint: 'بحث بالاسم أو الكود أو الباركود...',
      child: Obx(() {
        if (controller.posItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'لا توجد مواد من سطح المكتب في Firebase.\n'
                'شغّل سكربت المزامنة على جهاز SQL لنقل المخزون.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final items = controller.filteredPosItems;
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) => _posItemTile(controller, items[index]),
        );
      }),
    );
  }

  Widget _buildPanel({
    required String title,
    required IconData icon,
    required Color color,
    required RxString searchController,
    required String hint,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          color: color.withOpacity(0.08),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Obx(() => TextField(
                onChanged: (v) => searchController.value = v,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => searchController.value = '',
                        )
                      : null,
                  isDense: true,
                ),
              )),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _appProductTile(ProductLinkingController controller, ProductModel product) {
    final selected = controller.selectedAppProduct.value?.id == product.id;
    return Material(
      color: selected ? Colors.deepPurple.withOpacity(0.12) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => controller.selectAppProduct(product),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Colors.deepPurple : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? Colors.deepPurple : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.description.isNotEmpty
                          ? product.description
                          : 'بدون وصف',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'السعر: ${product.formattedPrice}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (product.isPosLinked) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.link, size: 14, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'مربوط بكود POS: ${product.posItemCode} — ${product.posItemName ?? ''}',
                              style: TextStyle(fontSize: 11, color: Colors.green.shade800),
                            ),
                          ),
                          TextButton(
                            onPressed: controller.isSaving.value
                                ? null
                                : () => _confirmUnlink(controller, product),
                            child: const Text('إلغاء', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _posItemTile(ProductLinkingController controller, PosItemModel item) {
    final selected = controller.selectedPosItem.value?.itemCode == item.itemCode;
    return Material(
      color: selected ? Colors.teal.withOpacity(0.12) : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => controller.selectPosItem(item),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Colors.teal : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? Colors.teal : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.displaySubtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    if (item.sellPrice != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'سعر البيع: ${item.sellPrice!.toStringAsFixed(0)} د.ع',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkBar(ProductLinkingController controller) {
    final app = controller.selectedAppProduct.value;
    final pos = controller.selectedPosItem.value;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (app != null || pos != null)
              Text(
                [
                  if (app != null) 'التطبيق: ${app.title}',
                  if (pos != null) 'POS: ${pos.itemName} (كود ${pos.itemCode})',
                ].join('  ←  '),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: controller.canLink && !controller.isSaving.value
                  ? controller.linkSelected
                  : null,
              icon: controller.isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.link),
              label: Text(controller.isSaving.value ? 'جاري الحفظ...' : 'حفظ الربط'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmUnlink(ProductLinkingController controller, ProductModel product) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('إلغاء الربط'),
        content: Text('إلغاء ربط «${product.title}» من مادة POS؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('لا')),
          TextButton(onPressed: () => Get.back(result: true), child: const Text('نعم')),
        ],
      ),
    );
    if (ok == true) {
      await controller.unlinkProduct(product);
      Get.snackbar('تم', 'تم إلغاء الربط');
    }
  }
}
