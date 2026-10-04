import '../../models/city.dart';
import 'crud_repository.dart';

abstract class CityRepository extends CrudRepository<City> {
  Future<String?> findNameById(String id);
}
