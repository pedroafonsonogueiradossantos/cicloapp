import '../data/firestore/firestore_codec.dart';

class Address {
  final String? id;
  final String personId;
  final String street;
  final String number;
  final String? neighborhood;
  final String? cityId;
  final String? cityName;
  final DateTime? createdAt;

  Address({
    this.id,
    required this.personId,
    required this.street,
    required this.number,
    this.neighborhood,
    this.cityId,
    this.cityName,
    this.createdAt,
  });

  factory Address.fromJson(String id, Map<String, dynamic> json) => Address(
        id: id,
        personId: json['personId'] as String? ?? '',
        street: json['street'] as String? ?? '',
        number: json['number']?.toString() ?? '',
        neighborhood: json['neighborhood'] as String?,
        cityId: json['cityId'] as String?,
        cityName: json['cityName'] as String?,
        createdAt: dateTimeFromFirestore(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'street': street,
        'number': number,
        'neighborhood': neighborhood,
        'cityId': cityId,
      };
}
