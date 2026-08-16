import 'dart:convert';

/// The person designated to be alerted if the user needs help during a trip.
///
/// This model is intentionally kept separate from [UserModel] so it can be
/// replaced or extended independently (e.g., to support multiple trusted
/// contacts) in a future phase.
class TrustedPersonModel {
  final String name;
  final String phone;
  final String relationship;

  const TrustedPersonModel({
    required this.name,
    required this.phone,
    required this.relationship,
  });

  TrustedPersonModel copyWith({
    String? name,
    String? phone,
    String? relationship,
  }) =>
      TrustedPersonModel(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        relationship: relationship ?? this.relationship,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory TrustedPersonModel.fromMap(Map<String, dynamic> map) =>
      TrustedPersonModel(
        name: map['name'] as String,
        phone: map['phone'] as String,
        relationship: map['relationship'] as String,
      );

  String toJson() => jsonEncode(toMap());

  factory TrustedPersonModel.fromJson(String source) =>
      TrustedPersonModel.fromMap(
        jsonDecode(source) as Map<String, dynamic>,
      );

  @override
  String toString() =>
      'TrustedPersonModel(name: $name, phone: $phone, relationship: $relationship)';
}
