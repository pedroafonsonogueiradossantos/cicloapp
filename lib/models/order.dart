import '../data/firestore/firestore_codec.dart';

class Order {
  final String? id;
  final String personId;
  final String? personName;
  final String? observation;
  final DateTime? orderDate;
  final DateTime? createdAt;
  final String? addressId;
  final String? addressStreet;
  final String? addressNumber;
  final String? addressNeighborhood;
  final String? addressCityName;
  final String? originAddressId;

  Order({
    this.id,
    required this.personId,
    this.personName,
    this.observation,
    this.orderDate,
    this.createdAt,
    this.addressId,
    this.addressStreet,
    this.addressNumber,
    this.addressNeighborhood,
    this.addressCityName,
    this.originAddressId,
  });

  bool get hasAddressSnapshot => addressStreet != null || addressNumber != null;

  factory Order.fromJson(String id, Map<String, dynamic> json) => Order(
        id: id,
        personId: json['personId'] as String? ?? '',
        personName: json['personName'] as String?,
        observation: json['observation'] as String?,
        orderDate: dateTimeFromFirestore(json['orderDate']),
        createdAt: dateTimeFromFirestore(json['createdAt']),
        addressStreet: json['addressStreet'] as String?,
        addressNumber: json['addressNumber'] as String?,
        addressNeighborhood: json['addressNeighborhood'] as String?,
        addressCityName: json['addressCityName'] as String?,
        originAddressId: json['originAddressId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'addressId': addressId,
        'observation': observation,
        'orderDate': orderDate,
      };
}
