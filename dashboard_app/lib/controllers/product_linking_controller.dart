import 'package:get/get.dart';
import '../models/pos_item_model.dart';
import '../models/product_model.dart';
import '../services/pos_item_service.dart';
import '../services/product_service.dart';

class ProductLinkingController extends GetxController {
  final RxList<ProductModel> appProducts = <ProductModel>[].obs;
  final RxList<PosItemModel> posItems = <PosItemModel>[].obs;

  final RxList<ProductModel> filteredAppProducts = <ProductModel>[].obs;
  final RxList<PosItemModel> filteredPosItems = <PosItemModel>[].obs;

  final RxString appSearchQuery = ''.obs;
  final RxString posSearchQuery = ''.obs;

  final Rxn<ProductModel> selectedAppProduct = Rxn<ProductModel>();
  final Rxn<PosItemModel> selectedPosItem = Rxn<PosItemModel>();

  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  final Rxn<DateTime> lastPosSync = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    ever(appSearchQuery, (_) => _filterAppProducts());
    ever(posSearchQuery, (_) => _filterPosItems());
    loadData();
  }

  Future<void> loadData() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final results = await Future.wait([
        ProductService.getAllProducts(),
        PosItemService.getAllItems(),
        PosItemService.getLastSyncTime(),
      ]);

      appProducts.value = results[0] as List<ProductModel>;
      posItems.value = results[1] as List<PosItemModel>;
      lastPosSync.value = results[2] as DateTime?;

      _filterAppProducts();
      _filterPosItems();
    } catch (e) {
      errorMessage.value = 'خطأ في تحميل البيانات: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _filterAppProducts() {
    final q = appSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      filteredAppProducts.value = List.from(appProducts);
      return;
    }
    filteredAppProducts.value = appProducts.where((p) {
      final code = p.posItemCode?.toString() ?? '';
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          code.contains(q) ||
          p.id.toLowerCase().contains(q);
    }).toList();
  }

  void _filterPosItems() {
    final q = posSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      filteredPosItems.value = List.from(posItems);
      return;
    }
    filteredPosItems.value = posItems.where((item) {
      return item.itemName.toLowerCase().contains(q) ||
          item.itemCode.toString().contains(q) ||
          (item.barcode ?? '').toLowerCase().contains(q) ||
          (item.kindName ?? '').toLowerCase().contains(q);
    }).toList();
  }

  void selectAppProduct(ProductModel product) {
    if (selectedAppProduct.value?.id == product.id) {
      selectedAppProduct.value = null;
      return;
    }
    selectedAppProduct.value = product;
  }

  void selectPosItem(PosItemModel item) {
    if (selectedPosItem.value?.itemCode == item.itemCode) {
      selectedPosItem.value = null;
      return;
    }
    selectedPosItem.value = item;
  }

  bool get canLink =>
      selectedAppProduct.value != null && selectedPosItem.value != null;

  Future<bool> linkSelected() async {
    final app = selectedAppProduct.value;
    final pos = selectedPosItem.value;
    if (app == null || pos == null) return false;

    try {
      isSaving.value = true;
      final ok = await ProductService.linkProductToPos(
        productId: app.id,
        posItem: pos,
      );
      if (!ok) {
        Get.snackbar('خطأ', 'تعذر حفظ الربط', backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
        return false;
      }

      final index = appProducts.indexWhere((p) => p.id == app.id);
      if (index >= 0) {
        final link = pos.toPosLinkMap();
        appProducts[index] = app.copyWith(
          posLink: link,
          stock: pos.balance,
        );
        _filterAppProducts();
      }

      selectedAppProduct.value = null;
      selectedPosItem.value = null;

      Get.snackbar(
        'تم الربط',
        'تم ربط «${app.title}» بمادة POS كود ${pos.itemCode}',
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
      return true;
    } catch (e) {
      Get.snackbar('خطأ', '$e', backgroundColor: Get.theme.colorScheme.error, colorText: Get.theme.colorScheme.onError);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> unlinkProduct(ProductModel product) async {
    try {
      isSaving.value = true;
      final ok = await ProductService.unlinkProductFromPos(product.id);
      if (!ok) return false;

      final index = appProducts.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        appProducts[index] = product.copyWith(
          posLink: null,
          stock: null,
          clearPosLink: true,
          clearStock: true,
        );
        _filterAppProducts();
      }
      if (selectedAppProduct.value?.id == product.id) {
        selectedAppProduct.value = null;
      }
      return true;
    } finally {
      isSaving.value = false;
    }
  }
}
