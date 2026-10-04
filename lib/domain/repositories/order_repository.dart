import '../../models/order.dart';
import 'crud_repository.dart';

abstract class OrderRepository extends CrudRepository<Order> {
  Future<List<Order>> listFiltered({String? personId, DateTime? startDate, DateTime? endDate});

  Future<bool> existsForPerson(String personId);
}
