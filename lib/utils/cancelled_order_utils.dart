import 'package:cloud_firestore/cloud_firestore.dart';

const Duration cancelledOrderRetention = Duration(minutes: 15);

bool isCancelledOrderData(Map<String, dynamic> data) {
  final orderstatus = (data['orderstatus'] ?? '').toString();
  final status = data['status'];
  return orderstatus == 'ملغي' ||
      status == 3 ||
      status == '3' ||
      status == 'ملغي';
}

DateTime? cancelledAtFromData(Map<String, dynamic> data) {
  final cancelledAt = data['cancelledAt'];
  if (cancelledAt is Timestamp) return cancelledAt.toDate();
  final updatedAt = data['updatedAt'];
  if (updatedAt is Timestamp) return updatedAt.toDate();
  return null;
}

bool shouldDeleteCancelledOrder(Map<String, dynamic> data, DateTime now) {
  if (!isCancelledOrderData(data)) return false;
  final at = cancelledAtFromData(data);
  if (at == null) return false;
  return now.difference(at) >= cancelledOrderRetention;
}
