import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ecommerce/controllers/Checkout_controller.dart';
import 'package:ecommerce/main.dart';

class Payment extends StatelessWidget {
  Payment({super.key});
  final Checkout_controller controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          GetBuilder<Checkout_controller>(
            builder: (builder) {
              return order(builder.price, builder.total_user, builder.profit);
            },
          ),
        ],
      ),
    );
  }

  order(price, total_user, profit) {
    return Container(
      margin: EdgeInsets.all(Get.width * 0.04),
      padding: EdgeInsets.all(Get.width * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.05),
            Colors.blue.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.deepPurple,
                  size: Get.width * 0.06,
                ),
              ),
              SizedBox(width: Get.width * 0.03),
              Text(
                '${'50'.tr}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: Get.width * 0.045,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),

          spaceH(Get.height * 0.03),

          // خط فاصل
          Padding(
            padding: EdgeInsets.symmetric(vertical: Get.height * 0.015),
            child: Divider(
              color: Colors.deepPurple.withOpacity(0.2),
              thickness: 1,
            ),
          ),

          // المجموع الكلي
          _buildPriceRow(
            '${'49'.tr} : ',
            '${formatter.format(price)} ${'18'.tr}',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: Get.width * 0.035,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? Colors.deepPurple : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: Get.width * 0.035,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isTotal ? Colors.deepPurple : Colors.black87,
          ),
        ),
      ],
    );
  }


  SizedBox spaceH(double size) {
    return SizedBox(height: size);
  }

  SizedBox spaceW(double size) {
    return SizedBox(width: size);
  }
}
