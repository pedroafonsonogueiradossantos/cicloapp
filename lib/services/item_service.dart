import '../di/service_locator.dart';
import '../domain/repositories/item_repository.dart';
import '../models/item.dart';

class ItemService {
  ItemService({ItemRepository? repository}) : _items = repository ?? sl<ItemRepository>();

  final ItemRepository _items;

  Future<List<Item>> list() => _items.list();

  Future<Item> create(Item item) {
    final now = DateTime.now().toUtc();
    return _items.create({...item.toJson(), 'createdAt': now, 'updatedAt': now});
  }

  Future<Item> update(String id, Item item) {
    return _items.update(id, {...item.toJson(), 'updatedAt': DateTime.now().toUtc()});
  }

  Future<void> delete(String id) => _items.delete(id);
}
