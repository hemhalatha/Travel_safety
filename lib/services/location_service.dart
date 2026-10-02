import 'package:geolocator/geolocator.dart';

/// Wraps geolocator with graceful error handling.
///
/// All methods return null / false on failure rather than throwing, so callers
/// never need to handle location errors — the trip continues safely on timer
/// alone when GPS is unavailable.
class LocationService {
  Position? _lastKnownPosition;

  Position? get lastKnownPosition => _lastKnownPosition;

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<bool> isPermissionGranted() async {
    try {
      final p = await Geolocator.checkPermission();
      return p == LocationPermission.always ||
          p == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Requests permission if not already granted.
  /// Returns true if permission is ultimately granted.
  Future<bool> requestPermission() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      return p == LocationPermission.always ||
          p == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  // ── Position ───────────────────────────────────────────────────────────────

  /// Returns the current device position, or null if unavailable.
  Future<Position?> getCurrentPosition() async {
    try {
      final granted = await isPermissionGranted();
      if (!granted) return null;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 10));

      _lastKnownPosition = position;
      return position;
    } catch (_) {
      return null;
    }
  }

  // ── Distance ───────────────────────────────────────────────────────────────

  /// Distance in kilometres between two positions.
  static double distanceKm(Position a, Position b) =>
      Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      ) /
      1000;
}
