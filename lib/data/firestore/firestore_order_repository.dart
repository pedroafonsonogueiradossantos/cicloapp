import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../domain/repositories/order_repository.dart';
import '../../models/order.dart';
import 'firestore_crud_repository.dart';

class FirestoreOrderRepository extends FirestoreCrudRepository<Order> implements OrderRepository {
  FirestoreOrderRepository()
      : super(
          collectionPath: 'orders',
          fromDoc: Order.fromJson,
          notFoundMessage: (id) => 'Pedido não encontrado: $id',
        );

  @override
  Future<List<Order>> listFiltered({String? personId, DateTime? startDate, DateTime? endDate}) {
    return list(where: (o) {
      if (personId != null && o.personId != personId) return false;
      if (startDate != null && (o.orderDate == null || o.orderDate!.isBefore(startDate))) return false;
      if (endDate != null && (o.orderDate == null || o.orderDate!.isAfter(endDate))) return false;
      return true;
    });
  }

  @override
  Future<bool> existsForPerson(String personId) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('orders').where('personId', isEqualTo: personId).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
}
