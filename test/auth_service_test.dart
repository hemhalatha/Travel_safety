import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_safety_app/models/trusted_person_model.dart';
import 'package:travel_safety_app/services/auth_service.dart';
import 'package:travel_safety_app/services/storage_service.dart';

void main() {
  group('AuthService', () {
    late AuthService auth;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      auth = AuthService(StorageService());
    });

    test('logs in when the same phone number is formatted differently',
        () async {
      await auth.register(
        name: 'Asha',
        phone: '+91 98765 43210',
        password: 'secret123',
        trustedPerson: const TrustedPersonModel(
          name: 'Maya',
          phone: '8888888888',
          relationship: 'Sister',
        ),
      );
      await auth.logout();

      final result = await auth.login(
        phone: '9876543210',
        password: 'secret123',
      );

      expect(result.success, isTrue);
      expect(result.error, isNull);
    });

    test('registers without trusted contacts', () async {
      final result = await auth.register(
        name: 'Asha',
        phone: '9876543210',
        password: 'secret123',
      );

      expect(result.success, isTrue);

      final user = await auth.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.trustedPeople, isEmpty);
    });
  });
}
