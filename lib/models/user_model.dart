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

  /// The user-designated trusted contact. Their phone number is entered
  /// exclusively by the user during registration; it is never hardcoded.
  final TrustedPersonModel trustedPerson;

  const UserModel({
    required this.name,
    required this.phone,
    required this.passwordHash,
    required this.trustedPerson,
  });

  UserModel copyWith({
    String? name,
    String? phone,
    String? passwordHash,
    TrustedPersonModel? trustedPerson,
  }) =>
      UserModel(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        passwordHash: passwordHash ?? this.passwordHash,
        trustedPerson: trustedPerson ?? this.trustedPerson,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'passwordHash': passwordHash,
        'trustedPerson': trustedPerson.toMap(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        name: map['name'] as String,
        phone: map['phone'] as String,
        passwordHash: map['passwordHash'] as String,
        trustedPerson: TrustedPersonModel.fromMap(
          map['trustedPerson'] as Map<String, dynamic>,
        ),
      );

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
