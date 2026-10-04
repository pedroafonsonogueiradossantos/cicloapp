import '../../models/address.dart';
import 'crud_repository.dart';

abstract class AddressRepository extends CrudRepository<Address> {
  Future<List<Address>> listByPerson(String personId);
  Future<bool> existsForPerson(String personId);
}
