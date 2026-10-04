import '../core/api_exception.dart';
import '../di/service_locator.dart';
import '../domain/repositories/address_repository.dart';
import '../domain/repositories/city_repository.dart';
import '../domain/repositories/order_item_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/repositories/person_repository.dart';
import '../models/order.dart';
import '../models/page_response.dart';

class OrderService {
  OrderService({
    OrderRepository? repository,
    PersonRepository? persons,
    AddressRepository? addresses,
    CityRepository? cities,
    OrderItemRepository? orderItems,
  })  : _orders = repository ?? sl<OrderRepository>(),
        _persons = persons ?? sl<PersonRepository>(),
        _addresses = addresses ?? sl<AddressRepository>(),
        _cities = cities ?? sl<CityRepository>(),
        _orderItems = orderItems ?? sl<OrderItemRepository>();

  final OrderRepository _orders;
  final PersonRepository _persons;
  final AddressRepository _addresses;
  final CityRepository _cities;
  final OrderItemRepository _orderItems;

  Future<PageResponse<Order>> page({
    String? personId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 0,
    int size = 20,
  }) async {
    final orders = await _orders.listFiltered(personId: personId, startDate: startDate, endDate: endDate);
    final withNames = await _withPersonNames(orders);
    withNames.sort((a, b) => (b.createdAt ?? DateTime.utc(0)).compareTo(a.createdAt ?? DateTime.utc(0)));

    final totalElements = withNames.length;
    final totalPages = (totalElements / size).ceil();
    final start = page * size;
    final content = start >= withNames.length ? <Order>[] : withNames.skip(start).take(size).toList();
    return PageResponse<Order>(
      content: content,
      page: page,
      size: size,
      totalElements: totalElements,
      totalPages: totalPages == 0 ? 1 : totalPages,
      last: page >= totalPages - 1,
    );
  }

  Future<Order> getById(String id) async {
    final order = await _orders.getById(id);
    return (await _withPersonNames([order])).first;
  }

  Future<Order> create(Order order) async {
    final snapshot = await _resolveAddressSnapshot(order.personId, order.addressId);
    final created = await _orders.create({
      'personId': order.personId,
      'observation': order.observation,
      'orderDate': order.orderDate,
      'createdAt': DateTime.now().toUtc(),
      ...snapshot,
    });
    return (await _withPersonNames([created])).first;
  }

  Future<Order> update(String id, Order order) async {
    final snapshot = await _resolveAddressSnapshot(order.personId, order.addressId);
    final updated = await _orders.update(id, {
      'personId': order.personId,
      'observation': order.observation,
      'orderDate': order.orderDate,
      ...snapshot,
    });
    return (await _withPersonNames([updated])).first;
  }

  Future<void> delete(String id) async {
    await _orderItems.deleteAllByOrder(id);
    await _orders.delete(id);
  }

  Future<List<Order>> _withPersonNames(List<Order> orders) async {
    if (orders.isEmpty) return orders;
    final ids = orders.map((o) => o.personId).toSet();
    final names = <String, String>{};
    for (final id in ids) {
      final name = await _persons.findNameById(id);
      if (name != null) names[id] = name;
    }
    return orders
        .map((o) => Order(
              id: o.id,
              personId: o.personId,
              personName: names[o.personId],
              observation: o.observation,
              orderDate: o.orderDate,
              createdAt: o.createdAt,
              addressId: o.addressId,
              addressStreet: o.addressStreet,
              addressNumber: o.addressNumber,
              addressNeighborhood: o.addressNeighborhood,
              addressCityName: o.addressCityName,
              originAddressId: o.originAddressId,
            ))
        .toList();
  }

  Future<Map<String, Object?>> _resolveAddressSnapshot(String personId, String? addressId) async {
    if (addressId == null) {
      return {
        'originAddressId': null,
        'addressStreet': null,
        'addressNumber': null,
        'addressNeighborhood': null,
        'addressCityName': null,
      };
    }
    final address = await _addresses.getById(addressId);
    if (address.personId != personId) {
      throw ApiException(message: 'Endereço não pertence ao cliente informado', statusCode: 400);
    }
    final cityName = address.cityId == null ? null : await _cities.findNameById(address.cityId!);
    return {
      'originAddressId': addressId,
      'addressStreet': address.street,
      'addressNumber': address.number,
      'addressNeighborhood': address.neighborhood,
      'addressCityName': cityName,
    };
  }
}
