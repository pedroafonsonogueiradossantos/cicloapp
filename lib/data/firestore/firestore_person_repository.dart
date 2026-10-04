import '../../domain/repositories/person_repository.dart';
import '../../models/person.dart';
import 'firestore_crud_repository.dart';

class FirestorePersonRepository extends FirestoreCrudRepository<Person> implements PersonRepository {
  FirestorePersonRepository()
      : super(
          collectionPath: 'persons',
          fromDoc: Person.fromJson,
          notFoundMessage: (id) => 'Pessoa não encontrada: $id',
        );

  @override
  Future<String?> findNameById(String id) async {
    final doc = await collection.doc(id).get();
    return doc.data()?['name'] as String?;
  }
}
