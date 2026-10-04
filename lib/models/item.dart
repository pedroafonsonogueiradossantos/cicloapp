import '../data/firestore/firestore_codec.dart';

class Item {
  final String? id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({this.id, required this.name, this.description, this.createdAt, this.updatedAt});

  factory Item.fromJson(String id, Map<String, dynamic> json) => Item(
        id: id,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        createdAt: dateTimeFromFirestore(json['createdAt']),
        updatedAt: dateTimeFromFirestore(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {'name': name, 'description': description};
}
