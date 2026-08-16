import 'auth_service.dart';
import 'storage_service.dart';

/// Minimal service locator for Phase 1.
///
/// Provides global access to shared service instances without adding a full
/// DI framework. Replace with Riverpod, GetIt, or similar in a later phase
/// when the app grows in complexity.
class ServiceLocator {
  ServiceLocator._();

  static final StorageService storage = StorageService();
  static final AuthService auth = AuthService(storage);
}
