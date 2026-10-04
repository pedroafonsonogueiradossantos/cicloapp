import '../core/api_exception.dart';
import '../di/service_locator.dart';
import '../domain/repositories/address_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/repositories/person_repository.dart';
import '../domain/repositories/phone_repository.dart';
import '../models/page_response.dart';
import '../models/person.dart';

class PersonService {
  PersonService({
    PersonRepository? repository,
    AddressRepository? addresses,
    PhoneRepository? phones,
    OrderRepository? orders,
  })  : _persons = repository ?? sl<PersonRepository>(),
        _addresses = addresses ?? sl<AddressRepository>(),
        _phones = phones ?? sl<PhoneRepository>(),
        _orders = orders ?? sl<OrderRepository>();

  final PersonRepository _persons;
  final AddressRepository _addresses;
  final PhoneRepository _phones;
  final OrderRepository _orders;

  Future<PageResponse<Person>> page({int page = 0, int size = 20, String? name}) {
    final query = (name != null && name.trim().isNotEmpty) ? name.trim().toLowerCase() : null;
    return _persons.page(
      where: query == null ? null : (p) => p.name.toLowerCase().contains(query),
      sort: (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      page: page,
      size: size,
    );
  }

  Future<Person> getById(String id) => _persons.getById(id);

  Future<Person> create(Person person) {
    final now = DateTime.now().toUtc();
    return _persons.create({...person.toJson(), 'createdAt': now, 'updatedAt': now});
  }

  Future<Person> update(String id, Person person) {
    return _persons.update(id, {...person.toJson(), 'updatedAt': DateTime.now().toUtc()});
  }

  Future<void> delete(String id) async {
    final hasRelated = await Future.wait([
      _addresses.existsForPerson(id),
      _phones.existsForPerson(id),
      _orders.existsForPerson(id),
    ]);
    if (hasRelated.any((exists) => exists)) {
      throw ApiException(
        message: 'Violação de integridade (registro relacionado existente ou dado duplicado)',
        statusCode: 409,
      );
    }
    await _persons.delete(id);
  }
}
