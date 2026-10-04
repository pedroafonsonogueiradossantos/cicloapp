class City {
  final String? id;
  final String name;

  City({this.id, required this.name});

  factory City.fromJson(String id, Map<String, dynamic> json) => City(
        id: id,
        name: json['name'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'name': name};
}
