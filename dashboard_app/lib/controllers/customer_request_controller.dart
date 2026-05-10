import 'package:get/get.dart';
import '../models/customer_request_model.dart';
import '../services/customer_request_service.dart';

class CustomerRequestController extends GetxController {
  final RxList<CustomerRequestModel> requests = <CustomerRequestModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadRequests();
  }

  Future<void> loadRequests() async {
    isLoading.value = true;
    try {
      final data = await CustomerRequestService.getAllRequests();
      requests.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }
}
