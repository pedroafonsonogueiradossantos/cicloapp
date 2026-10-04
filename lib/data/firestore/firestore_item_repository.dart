import '../../domain/repositories/item_repository.dart';
import '../../models/item.dart';
import 'firestore_crud_repository.dart';

class FirestoreItemRepository extends FirestoreCrudRepository<Item> implements ItemRepository {
  FirestoreItemRepository()
      : super(
          collectionPath: 'items',
          fromDoc: Item.fromJson,
          notFoundMessage: (id) => 'Item não encontrado: $id',
        );

  @override
  Future<String?> findNameById(String id) async {
    final doc = await collection.doc(id).get();
    return doc.data()?['name'] as String?;
  }
}
