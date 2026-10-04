import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/address_repository.dart';
import '../../models/address.dart';
import 'firestore_crud_repository.dart';

class FirestoreAddressRepository extends FirestoreCrudRepository<Address> implements AddressRepository {
  FirestoreAddressRepository()
      : super(
          collectionPath: 'addresses',
          fromDoc: Address.fromJson,
          notFoundMessage: (id) => 'Endereço não encontrado: $id',
        );

  @override
  Future<List<Address>> listByPerson(String personId) async {
    final addresses = await list(where: (a) => a.personId == personId);
    if (addresses.isEmpty) return addresses;

    final cities = await FirebaseFirestore.instance.collection('cities').get();
    final cityNames = {for (final d in cities.docs) d.id: d.data()['name'] as String?};
    return addresses
        .map((a) => a.cityId == null
            ? a
            : Address(
                id: a.id,
                personId: a.personId,
                street: a.street,
                number: a.number,
                neighborhood: a.neighborhood,
                cityId: a.cityId,
                cityName: cityNames[a.cityId],
                createdAt: a.createdAt,
              ))
        .toList();
  }

  @override
  Future<bool> existsForPerson(String personId) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('addresses').where('personId', isEqualTo: personId).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
}
