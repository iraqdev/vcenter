import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pos_item_model.dart';

class PosItemService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String collection = 'pos_items';

  static Future<List<PosItemModel>> getAllItems() async {
    try {
      final snap = await _db.collection(collection).get();
      final items = snap.docs
          .map((doc) => PosItemModel.fromFirestore(doc.data(), doc.id))
          .toList();
      items.sort((a, b) => a.itemName.compareTo(b.itemName));
      return items;
    } catch (e) {
      print('خطأ في جلب مواد سطح المكتب: $e');
      return [];
    }
  }

  static Future<DateTime?> getLastSyncTime() async {
    try {
      final doc = await _db.collection('pos_sync_meta').doc('last').get();
      if (!doc.exists) return null;
      final ts = doc.data()?['syncedAt'];
      if (ts is Timestamp) return ts.toDate();
      return null;
    } catch (_) {
      return null;
    }
  }
}
