import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_model.dart';

/// Manages active trip state and trip history.
///
/// All persistence uses [SharedPreferences] directly — trip data is a separate
/// domain from user/auth data managed by [StorageService].
///
/// Keys use a `ts_` prefix to avoid clashes with [StorageService] keys.
class TripService {
  static const String _keyActiveTrip = 'ts_active_trip_v1';
  static const String _keyTripHistory = 'ts_trip_history_v1';
  static const int _maxHistoryItems = 20;

  // ── Active trip ────────────────────────────────────────────────────────────

  /// Creates and persists a new active trip.
  Future<void> startTrip({
    required String destination,
    double? destinationLatitude,
    double? destinationLongitude,
    double? routeDistanceKm,
    List<TripCoordinate> routePath = const [],
    required int durationMinutes,
  }) async {
    final trip = TripModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      destination: destination.trim(),
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
      routeDistanceKm: routeDistanceKm,
      routePath: routePath,
      durationMinutes: durationMinutes,
      startTime: DateTime.now(),
      status: TripStatus.active,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveTrip, trip.toJson());
  }

  /// Marks the active trip as completed and moves it to history.
  Future<void> endTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final activeJson = prefs.getString(_keyActiveTrip);
    if (activeJson != null) {
      try {
        final trip = TripModel.fromJson(activeJson);
        final completed = trip.copyWith(
          endTime: DateTime.now(),
          status: TripStatus.completed,
        );
        await _addToHistory(prefs, completed);
      } catch (_) {
        // Corrupt data — just remove it.
      }
    }
    await prefs.remove(_keyActiveTrip);
  }

  /// Returns the current active trip, or null if none exists.
  Future<TripModel?> getActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyActiveTrip);
    if (json == null) return null;
    try {
      final trip = TripModel.fromJson(json);
      // Only return if still in active status.
      return trip.isActive ? trip : null;
    } catch (_) {
      return null;
    }
  }

  // ── History ────────────────────────────────────────────────────────────────

  /// Returns completed trips, most recent first, capped at [_maxHistoryItems].
  Future<List<TripModel>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_keyTripHistory);
      if (jsonList == null || jsonList.isEmpty) return const [];
      final result = <TripModel>[];
      for (final j in jsonList) {
        if (j.isNotEmpty) {
          try {
            final model = TripModel.fromJson(j);
            result.add(model);
          } catch (_) {}
        }
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _addToHistory(SharedPreferences prefs, TripModel trip) async {
    final existing = prefs.getStringList(_keyTripHistory) ?? [];
    existing.insert(0, trip.toJson());
    final capped = existing.take(_maxHistoryItems).toList();
    await prefs.setStringList(_keyTripHistory, capped);
  }
}
