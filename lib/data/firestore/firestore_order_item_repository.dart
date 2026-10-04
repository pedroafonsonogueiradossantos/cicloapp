import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/order_item_repository.dart';
import '../../models/order_item.dart';
import 'firestore_crud_repository.dart';

class FirestoreOrderItemRepository extends FirestoreCrudRepository<OrderItem> implements OrderItemRepository {
  FirestoreOrderItemRepository()
      : super(
          collectionPath: 'orderItems',
          fromDoc: OrderItem.fromJson,
          notFoundMessage: (id) => 'Item de pedido não encontrado: $id',
        );

  @override
  Future<List<OrderItem>> listByOrder(String orderId) => list(where: (i) => i.orderId == orderId);

  @override
  Future<void> deleteAllByOrder(String orderId) async {
    final firestore = FirebaseFirestore.instance;
    final items = await firestore.collection('orderItems').where('orderId', isEqualTo: orderId).get();
    final batch = firestore.batch();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
