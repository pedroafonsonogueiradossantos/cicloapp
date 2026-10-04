import '../di/service_locator.dart';
import '../domain/repositories/item_repository.dart';
import '../domain/repositories/order_item_repository.dart';
import '../models/order_item.dart';

class OrderItemService {
  OrderItemService({OrderItemRepository? repository, ItemRepository? items})
      : _orderItems = repository ?? sl<OrderItemRepository>(),
        _items = items ?? sl<ItemRepository>();

  final OrderItemRepository _orderItems;
  final ItemRepository _items;

  Future<List<OrderItem>> listByOrder(String orderId) async {
    final items = await _orderItems.listByOrder(orderId);
    return _withItemNames(items);
  }

  Future<OrderItem> create(OrderItem item) async {
    final created = await _orderItems.create(item.toJson());
    return (await _withItemNames([created])).first;
  }

  Future<OrderItem> update(String id, OrderItem item) async {
    final updated = await _orderItems.update(id, item.toJson());
    return (await _withItemNames([updated])).first;
  }

  Future<void> delete(String id) => _orderItems.delete(id);

  Future<List<OrderItem>> _withItemNames(List<OrderItem> items) async {
    if (items.isEmpty) return items;
    final ids = items.map((i) => i.itemId).toSet();
    final names = <String, String>{};
    for (final id in ids) {
      final name = await _items.findNameById(id);
      if (name != null) names[id] = name;
    }
    return items
        .map((i) => OrderItem(
              id: i.id,
              orderId: i.orderId,
              itemId: i.itemId,
              itemName: names[i.itemId],
              quantity: i.quantity,
              unitPrice: i.unitPrice,
              maintenanceIntervalMonths: i.maintenanceIntervalMonths,
            ))
        .toList();
  }
}
