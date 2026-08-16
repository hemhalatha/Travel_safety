import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_safety_app/models/trip_model.dart';
import 'package:travel_safety_app/services/trip_service.dart';

void main() {
  group('TripModel Tests', () {
    test('Serialization and deserialization', () {
      final now = DateTime.now();
      final trip = TripModel(
        id: '12345',
        destination: 'Chennai Central',
        durationMinutes: 30,
        startTime: now,
        status: TripStatus.active,
      );

      final jsonStr = trip.toJson();
      final decoded = TripModel.fromJson(jsonStr);

      expect(decoded.id, equals('12345'));
      expect(decoded.destination, equals('Chennai Central'));
      expect(decoded.durationMinutes, equals(30));
      expect(decoded.status, equals(TripStatus.active));
      expect(decoded.isActive, isTrue);
      expect(decoded.isDelayed, isFalse);
    });

    test('Delayed trip calculation', () {
      final pastStart = DateTime.now().subtract(const Duration(minutes: 45));
      final trip = TripModel(
        id: '999',
        destination: 'Airport',
        durationMinutes: 30,
        startTime: pastStart,
        status: TripStatus.active,
      );

      expect(trip.isDelayed, isTrue);
      expect(trip.remainingMinutes, lessThan(0));
    });

    test('Completed trip calculation', () {
      final start = DateTime.now().subtract(const Duration(minutes: 60));
      final end = DateTime.now().subtract(const Duration(minutes: 15));
      final trip = TripModel(
        id: '888',
        destination: 'Beach',
        durationMinutes: 30,
        startTime: start,
        endTime: end,
        status: TripStatus.completed,
      );

      expect(trip.isActive, isFalse);
      expect(trip.isDelayed, isFalse);
      expect(trip.elapsed.inMinutes, equals(45));
    });
  });

  group('TripService Tests', () {
    late TripService tripService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tripService = TripService();
    });

    test('Empty trip history returns empty list safely', () async {
      final history = await tripService.getHistory();
      expect(history, isEmpty);
      expect(history, isA<List<TripModel>>());
    });

    test('Active trip management (start & end)', () async {
      expect(await tripService.getActiveTrip(), isNull);

      await tripService.startTrip(
        destination: 'T. Nagar',
        durationMinutes: 45,
      );

      final active = await tripService.getActiveTrip();
      expect(active, isNotNull);
      expect(active!.destination, equals('T. Nagar'));
      expect(active.durationMinutes, equals(45));
      expect(active.isActive, isTrue);

      await tripService.endTrip();

      expect(await tripService.getActiveTrip(), isNull);

      final history = await tripService.getHistory();
      expect(history.length, equals(1));
      expect(history.first.destination, equals('T. Nagar'));
      expect(history.first.status, equals(TripStatus.completed));
    });
  });
}
