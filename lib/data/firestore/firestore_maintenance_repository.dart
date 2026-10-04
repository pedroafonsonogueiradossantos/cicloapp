import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../domain/repositories/maintenance_repository.dart';
import '../../models/maintenance_due.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';

class _Candidate {
  _Candidate({
    required this.personId,
    required this.itemId,
    required this.lastOrderId,
    required this.effectiveDate,
    required this.intervalMonths,
  });

  final String personId;
  final String itemId;
  final String lastOrderId;
  final DateTime effectiveDate;
  final int intervalMonths;
}
// rever essa implementação
class FirestoreMaintenanceRepository implements MaintenanceRepository {
  @override
  Future<List<MaintenanceDue>> due({required DateTime from, required DateTime to}) async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore.collection('orderItems').get(),
      firestore.collection('orders').get(),
      firestore.collection('persons').get(),
      firestore.collection('items').get(),
      firestore.collection('phones').get(),
    ]);

    final orderItems = results[0]
        .docs
        .map((d) => OrderItem.fromJson(d.id, d.data()))
        .where((i) => i.maintenanceIntervalMonths != null);
    final orders = {for (final d in results[1].docs) d.id: Order.fromJson(d.id, d.data())};
    final personNames = {for (final d in results[2].docs) d.id: d.data()['name'] as String? ?? ''};
    final itemNames = {for (final d in results[3].docs) d.id: d.data()['name'] as String? ?? ''};

    final phonesByPerson = <String, List<String>>{};
    for (final d in results[4].docs) {
      final personId = d.data()['personId'] as String?;
      final number = d.data()['number'] as String?;
      if (personId != null && number != null && number.isNotEmpty) {
        (phonesByPerson[personId] ??= []).add(number);
      }
    }

    final latest = <String, _Candidate>{};
    for (final oi in orderItems) {
      final order = orders[oi.orderId];
      if (order == null) continue;
      final effectiveDate = order.orderDate ?? order.createdAt;
      if (effectiveDate == null) continue;
      final key = '${order.personId}|${oi.itemId}';
      final existing = latest[key];
      if (existing == null || effectiveDate.isAfter(existing.effectiveDate)) {
        latest[key] = _Candidate(
          personId: order.personId,
          itemId: oi.itemId,
          lastOrderId: order.id!,
          effectiveDate: effectiveDate,
          intervalMonths: oi.maintenanceIntervalMonths!,
        );
      }
    }

    final due = <MaintenanceDue>[];
    for (final c in latest.values) {
      final dueDate = DateTime.utc(c.effectiveDate.year, c.effectiveDate.month + c.intervalMonths, c.effectiveDate.day);
      if (dueDate.isBefore(from) || dueDate.isAfter(to)) continue;
      due.add(MaintenanceDue(
        personId: c.personId,
        personName: personNames[c.personId] ?? '',
        itemId: c.itemId,
        itemName: itemNames[c.itemId] ?? '',
        lastOrderId: c.lastOrderId,
        lastOrderDate: c.effectiveDate,
        maintenanceIntervalMonths: c.intervalMonths,
        dueDate: dueDate,
        phoneNumbers: phonesByPerson[c.personId] ?? [],
      ));
    }
    due.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return due;
  }
}
