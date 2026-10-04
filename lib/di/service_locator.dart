import 'package:get_it/get_it.dart';

import '../data/firestore/firebase_auth_repository.dart';
import '../data/firestore/firestore_address_repository.dart';
import '../data/firestore/firestore_city_repository.dart';
import '../data/firestore/firestore_item_repository.dart';
import '../data/firestore/firestore_maintenance_repository.dart';
import '../data/firestore/firestore_order_item_repository.dart';
import '../data/firestore/firestore_order_repository.dart';
import '../data/firestore/firestore_person_repository.dart';
import '../data/firestore/firestore_phone_repository.dart';
import '../domain/repositories/address_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/city_repository.dart';
import '../domain/repositories/item_repository.dart';
import '../domain/repositories/maintenance_repository.dart';
import '../domain/repositories/order_item_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/repositories/person_repository.dart';
import '../domain/repositories/phone_repository.dart';
import '../providers/auth_provider.dart';
import '../services/address_service.dart';
import '../services/city_service.dart';
import '../services/item_service.dart';
import '../services/maintenance_service.dart';
import '../services/order_item_service.dart';
import '../services/order_service.dart';
import '../services/person_service.dart';
import '../services/phone_service.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  if (sl.isRegistered<AuthRepository>()) return;

  sl.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
  sl.registerLazySingleton<PersonRepository>(() => FirestorePersonRepository());
  sl.registerLazySingleton<AddressRepository>(() => FirestoreAddressRepository());
  sl.registerLazySingleton<PhoneRepository>(() => FirestorePhoneRepository());
  sl.registerLazySingleton<CityRepository>(() => FirestoreCityRepository());
  sl.registerLazySingleton<ItemRepository>(() => FirestoreItemRepository());
  sl.registerLazySingleton<OrderRepository>(() => FirestoreOrderRepository());
  sl.registerLazySingleton<OrderItemRepository>(() => FirestoreOrderItemRepository());
  sl.registerLazySingleton<MaintenanceRepository>(() => FirestoreMaintenanceRepository());

  sl.registerLazySingleton<AuthProvider>(() => AuthProvider(sl<AuthRepository>()));
  sl.registerLazySingleton<PersonService>(() => PersonService());
  sl.registerLazySingleton<AddressService>(() => AddressService());
  sl.registerLazySingleton<PhoneService>(() => PhoneService());
  sl.registerLazySingleton<CityService>(() => CityService());
  sl.registerLazySingleton<ItemService>(() => ItemService());
  sl.registerLazySingleton<OrderService>(() => OrderService());
  sl.registerLazySingleton<OrderItemService>(() => OrderItemService());
  sl.registerLazySingleton<MaintenanceService>(() => MaintenanceService());
}
