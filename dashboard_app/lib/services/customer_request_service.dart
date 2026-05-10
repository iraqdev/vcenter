import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_request_model.dart';

class CustomerRequestService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'customer_requests';

  static Future<List<CustomerRequestModel>> getAllRequests() async {
    try {
      final query = await _db.collection(_collection).get();
      final requests = query.docs
          .map(
            (doc) => CustomerRequestModel.fromFirestore(
              doc.data(),
              doc.id,
            ),
          )
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      return [];
    }
  }
}
