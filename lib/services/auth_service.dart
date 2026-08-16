import 'dart:convert';

import '../models/trusted_person_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Handles registration, login, logout, and current-user resolution.
///
/// SECURITY NOTICE — PROTOTYPE ONLY:
/// Passwords are base64-encoded before storage. Base64 is NOT a hash function
/// and provides no cryptographic security. This approach is used solely so
/// plaintext passwords are not stored as-is in SharedPreferences.
///
/// Before any production deployment, replace this service with proper
/// server-side authentication (Firebase Auth, Supabase, a custom server
/// with bcrypt/Argon2, etc.). Do NOT log, print, or expose the raw password
/// anywhere in the application.
class AuthService {
  final StorageService _storage;

  AuthService(this._storage);

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  String _encodePassword(String password) =>
      base64Encode(utf8.encode(password));

  bool _verifyPassword(String candidate, String stored) =>
      _encodePassword(candidate) == stored;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Registers a new user account with the given trusted person details.
  ///
  /// Returns a record with [success] and an optional [error] message.
  Future<({bool success, String? error})> register({
    required String name,
    required String phone,
    required String password,
    required TrustedPersonModel trustedPerson,
  }) async {
    final existing = await _storage.getUser();
    if (existing != null) {
      return (
        success: false,
        error:
            'An account already exists on this device. Please sign in instead.',
      );
    }

    final user = UserModel(
      name: name.trim(),
      phone: phone.trim(),
      passwordHash: _encodePassword(password),
      trustedPerson: trustedPerson,
    );

    await _storage.saveUser(user);
    await _storage.setLoggedIn(value: true);
    return (success: true, error: null);
  }

  /// Authenticates an existing user by phone and password.
  Future<({bool success, String? error})> login({
    required String phone,
    required String password,
  }) async {
    final user = await _storage.getUser();

    if (user == null) {
      return (
        success: false,
        error: 'No account found. Please register first.',
      );
    }

    final phoneMatch = user.phone == phone.trim();
    final passwordMatch = _verifyPassword(password, user.passwordHash);

    if (!phoneMatch || !passwordMatch) {
      return (
        success: false,
        error: 'Incorrect phone number or password.',
      );
    }

    await _storage.setLoggedIn(value: true);
    return (success: true, error: null);
  }

  /// Clears the current session. Account data is preserved.
  Future<void> logout() => _storage.clearSession();

  /// Returns the current user if a valid session exists, otherwise null.
  Future<UserModel?> getCurrentUser() async {
    final loggedIn = await _storage.isLoggedIn();
    if (!loggedIn) return null;
    return _storage.getUser();
  }

  Future<bool> isLoggedIn() => _storage.isLoggedIn();

  Future<bool> hasRegisteredUser() => _storage.hasRegisteredUser();

  /// Updates only the trusted person details; other user fields are unchanged.
  Future<void> updateTrustedPerson(TrustedPersonModel trustedPerson) async {
    final user = await _storage.getUser();
    if (user == null) return;
    await _storage.saveUser(user.copyWith(trustedPerson: trustedPerson));
  }
}
