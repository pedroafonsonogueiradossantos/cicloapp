import '../di/service_locator.dart';
import '../domain/repositories/city_repository.dart';
import '../models/city.dart';

class CityService {
  CityService({CityRepository? repository}) : _cities = repository ?? sl<CityRepository>();

  final CityRepository _cities;

  Future<List<City>> list() => _cities.list();

  Future<City> create(City city) => _cities.create(city.toJson());

  Future<City> update(String id, City city) => _cities.update(id, city.toJson());

  Future<void> delete(String id) => _cities.delete(id);
}
