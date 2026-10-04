import '../../domain/repositories/city_repository.dart';
import '../../models/city.dart';
import 'firestore_crud_repository.dart';

class FirestoreCityRepository extends FirestoreCrudRepository<City> implements CityRepository {
  FirestoreCityRepository()
      : super(
          collectionPath: 'cities',
          fromDoc: City.fromJson,
          notFoundMessage: (id) => 'Cidade não encontrada: $id',
        );

  @override
  Future<String?> findNameById(String id) async {
    final doc = await collection.doc(id).get();
    return doc.data()?['name'] as String?;
  }
}
