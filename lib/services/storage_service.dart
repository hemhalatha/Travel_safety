import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Isolated local persistence layer.
///
/// All SharedPreferences access is contained here. To migrate to a different
/// storage backend (secure storage, SQLite, a REST API, etc.), replace only
/// this class — no screen or service code should change.
class StorageService {
  static const String _keyUser = 'ts_user_v1';
  static const String _keyIsLoggedIn = 'ts_logged_in';

  // ---------------------------------------------------------------------------
  // User
  // ---------------------------------------------------------------------------

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, user.toJson());
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyUser);
    if (json == null) return null;
    try {
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasRegisteredUser() async {
    final user = await getUser();
    return user != null;
  }

  // ---------------------------------------------------------------------------
  // Session
  // ---------------------------------------------------------------------------

  Future<void> setLoggedIn({required bool value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, value);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Clears the session flag only.
  /// Registered account data is preserved so the user can log in again.
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}
