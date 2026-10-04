import '../../models/item.dart';
import 'crud_repository.dart';

abstract class ItemRepository extends CrudRepository<Item> {
  Future<String?> findNameById(String id);
}
