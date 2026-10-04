import '../../models/order_item.dart';
import 'crud_repository.dart';

abstract class OrderItemRepository extends CrudRepository<OrderItem> {
  Future<List<OrderItem>> listByOrder(String orderId);

  /// Used by OrderService.delete to cascade-delete an order's items,
  /// mirroring the old backend's ON DELETE CASCADE.
  Future<void> deleteAllByOrder(String orderId);
}
