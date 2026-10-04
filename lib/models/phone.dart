enum PhoneType {
  mobile,
  landline,
  whatsapp;

  static PhoneType fromJson(String? value) {
    return PhoneType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => PhoneType.mobile,
    );
  }

  String get label => switch (this) {
        PhoneType.mobile => 'Celular',
        PhoneType.landline => 'Fixo',
        PhoneType.whatsapp => 'WhatsApp',
      };
}

class Phone {
  final String? id;
  final String personId;
  final String number;
  final PhoneType type;

  Phone({this.id, required this.personId, required this.number, this.type = PhoneType.mobile});

  factory Phone.fromJson(String id, Map<String, dynamic> json) => Phone(
        id: id,
        personId: json['personId'] as String? ?? '',
        number: json['number'] as String? ?? '',
        type: PhoneType.fromJson(json['type'] as String?),
      );

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'number': number,
        'type': type.name,
      };
}
