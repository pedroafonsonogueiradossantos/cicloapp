import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/phone_repository.dart';
import '../../models/phone.dart';
import 'firestore_crud_repository.dart';

class FirestorePhoneRepository extends FirestoreCrudRepository<Phone> implements PhoneRepository {
  FirestorePhoneRepository()
      : super(
          collectionPath: 'phones',
          fromDoc: Phone.fromJson,
          notFoundMessage: (id) => 'Telefone não encontrado: $id',
        );

  @override
  Future<List<Phone>> listByPerson(String personId) => list(where: (p) => p.personId == personId);

  @override
  Future<bool> existsForPerson(String personId) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('phones').where('personId', isEqualTo: personId).limit(1).get();
    return snapshot.docs.isNotEmpty;
  }
}
