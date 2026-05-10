import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/customer_request_controller.dart';

class CustomerRequestsScreen extends StatelessWidget {
  CustomerRequestsScreen({super.key});

  final CustomerRequestController controller = Get.find<CustomerRequestController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طلبات تسجيل الزبائن'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: controller.loadRequests,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: Colors.deepPurple));
        }
        if (controller.requests.isEmpty) {
          return Center(
            child: Text(
              'لا توجد طلبات حالياً',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadRequests,
          color: Colors.deepPurple,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: controller.requests.length,
            itemBuilder: (context, index) {
              final item = controller.requests[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      _row('الهاتف', item.phone),
                      _row('المنطقة/المحافظة', item.areaOrGovernorate),
                      if (item.email.trim().isNotEmpty) _row('الإيميل', item.email),
                      _row('وقت الإرسال', DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt)),
                      SizedBox(height: 8),
                      Text(
                        'شرح الطلب',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.deepPurple),
                      ),
                      SizedBox(height: 4),
                      Text(item.requestDetails),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$title: ', style: TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
