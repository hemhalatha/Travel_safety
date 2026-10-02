import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:travel_safety_app/models/trusted_person_model.dart';
import 'package:travel_safety_app/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('serializes multiple trusted people', () {
      const user = UserModel(
        name: 'Asha',
        phone: '9999999999',
        passwordHash: 'encoded',
        trustedPeople: [
          TrustedPersonModel(
            name: 'Maya',
            phone: '8888888888',
            relationship: 'Sister',
          ),
          TrustedPersonModel(
            name: 'Ravi',
            phone: '7777777777',
            relationship: 'Friend',
          ),
        ],
      );

      final decoded = UserModel.fromJson(user.toJson());

      expect(decoded.trustedPeople, hasLength(2));
      expect(decoded.trustedPerson.name, equals('Maya'));
      expect(decoded.trustedPeople.last.name, equals('Ravi'));
    });

    test('migrates legacy single trustedPerson JSON into trustedPeople', () {
      final legacyJson = jsonEncode({
        'name': 'Asha',
        'phone': '9999999999',
        'passwordHash': 'encoded',
        'trustedPerson': {
          'name': 'Maya',
          'phone': '8888888888',
          'relationship': 'Sister',
        },
      });

      final decoded = UserModel.fromJson(legacyJson);

      expect(decoded.trustedPeople, hasLength(1));
      expect(decoded.trustedPeople.first.name, equals('Maya'));
    });

    test('keeps a legacy trustedPeople list after JSON decoding', () {
      final json = jsonEncode({
        'name': 'Asha',
        'phone': '+91 98765 43210',
        'passwordHash': 'encoded',
        'trustedPeople': [
          {
            'name': 'Maya',
            'phone': '8888888888',
            'relationship': 'Sister',
          },
        ],
      });

      final decoded = UserModel.fromJson(json);

      expect(decoded.trustedPeople, hasLength(1));
      expect(decoded.trustedPeople.first.phone, equals('8888888888'));
    });

    test('supports users without trusted contacts', () {
      const user = UserModel(
        name: 'Asha',
        phone: '9999999999',
        passwordHash: 'encoded',
        trustedPeople: [],
      );

      final decoded = UserModel.fromJson(user.toJson());

      expect(decoded.trustedPeople, isEmpty);
    });
  });
}
