import '../di/service_locator.dart';
import '../domain/repositories/phone_repository.dart';
import '../models/phone.dart';

class PhoneService {
  PhoneService({PhoneRepository? repository}) : _phones = repository ?? sl<PhoneRepository>();

  final PhoneRepository _phones;

  Future<List<Phone>> listByPerson(String personId) => _phones.listByPerson(personId);

  Future<Phone> create(Phone phone) => _phones.create(phone.toJson());

  Future<Phone> update(String id, Phone phone) => _phones.update(id, phone.toJson());

  Future<void> delete(String id) => _phones.delete(id);
}
