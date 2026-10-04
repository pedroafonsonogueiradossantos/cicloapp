import '../../models/person.dart';
import 'crud_repository.dart';

abstract class PersonRepository extends CrudRepository<Person> {
  Future<String?> findNameById(String id);
}
