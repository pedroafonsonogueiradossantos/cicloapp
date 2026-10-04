import '../di/service_locator.dart';
import '../domain/repositories/address_repository.dart';
import '../models/address.dart';

class AddressService {
  AddressService({AddressRepository? repository}) : _addresses = repository ?? sl<AddressRepository>();

  final AddressRepository _addresses;

  Future<List<Address>> listByPerson(String personId) => _addresses.listByPerson(personId);

  Future<Address> create(Address address) {
    return _addresses.create({...address.toJson(), 'createdAt': DateTime.now().toUtc()});
  }

  Future<Address> update(String id, Address address) => _addresses.update(id, address.toJson());

  Future<void> delete(String id) => _addresses.delete(id);
}
