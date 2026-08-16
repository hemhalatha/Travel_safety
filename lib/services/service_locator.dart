import 'auth_service.dart';
import 'location_service.dart';
import 'storage_service.dart';
import 'trip_service.dart';

/// Minimal service locator providing global singleton access to all services.
///
/// Replace with Riverpod, GetIt, or similar when the app grows in complexity.
class ServiceLocator {
  ServiceLocator._();

  // Phase 1 services
  static final StorageService storage = StorageService();
  static final AuthService auth = AuthService(storage);

  // Phase 2 services
  static final TripService trip = TripService();
  static final LocationService location = LocationService();
}
