import 'dart:convert';

import 'trusted_person_model.dart';

/// Represents a registered user account.
///
/// SECURITY NOTE: [passwordHash] stores a base64-encoded password for prototype
/// purposes only. Base64 is encoding, not hashing — it provides no real
/// security. Replace [AuthService] with a proper backend authentication system
/// (Firebase Auth, Supabase, or a server using bcrypt/Argon2) before any
/// production deployment. Do NOT log or display this field.
class UserModel {
  final String name;
  final String phone;

  /// Base64-encoded password. Prototype only — see security note above.
  final String passwordHash;

  /// User-designated trusted contacts. Phone numbers are entered exclusively by
  /// the user; they are never hardcoded.
  final List<TrustedPersonModel> trustedPeople;

  const UserModel({
    required this.name,
    required this.phone,
    required this.passwordHash,
    required this.trustedPeople,
  });

  TrustedPersonModel get trustedPerson => trustedPeople.first;

  TrustedPersonModel? get primaryTrustedPerson =>
      trustedPeople.isEmpty ? null : trustedPeople.first;

  UserModel copyWith({
    String? name,
    String? phone,
    String? passwordHash,
    List<TrustedPersonModel>? trustedPeople,
    TrustedPersonModel? trustedPerson,
  }) =>
      UserModel(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        passwordHash: passwordHash ?? this.passwordHash,
        trustedPeople: trustedPeople ??
            (trustedPerson != null ? [trustedPerson] : this.trustedPeople),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'passwordHash': passwordHash,
        'trustedPeople': trustedPeople.map((p) => p.toMap()).toList(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final trustedPeopleRaw = map['trustedPeople'];
    final trustedPeople = trustedPeopleRaw is List
        ? trustedPeopleRaw
            .whereType<Map<String, dynamic>>()
            .map(TrustedPersonModel.fromMap)
            .toList()
        : <TrustedPersonModel>[];

    final legacyTrustedPerson = map['trustedPerson'];
    if (trustedPeople.isEmpty && legacyTrustedPerson is Map<String, dynamic>) {
      trustedPeople.add(TrustedPersonModel.fromMap(legacyTrustedPerson));
    }

    return UserModel(
      name: map['name'] as String,
      phone: map['phone'] as String,
      passwordHash: map['passwordHash'] as String,
      trustedPeople: trustedPeople,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
