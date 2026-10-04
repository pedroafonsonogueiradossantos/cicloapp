import '../../models/phone.dart';
import 'crud_repository.dart';

abstract class PhoneRepository extends CrudRepository<Phone> {
  Future<List<Phone>> listByPerson(String personId);

  Future<bool> existsForPerson(String personId);
}
