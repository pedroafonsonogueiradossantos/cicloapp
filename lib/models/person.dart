import '../data/firestore/firestore_codec.dart';

class Person {
  final String? id;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Person({this.id, required this.name, this.createdAt, this.updatedAt});

  factory Person.fromJson(String id, Map<String, dynamic> json) => Person(
        id: id,
        name: json['name'] as String? ?? '',
        createdAt: dateTimeFromFirestore(json['createdAt']),
        updatedAt: dateTimeFromFirestore(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {'name': name};
}
