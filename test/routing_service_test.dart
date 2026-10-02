import 'package:flutter_test/flutter_test.dart';
import 'package:travel_safety_app/services/routing_service.dart';

void main() {
  group('RoutingService', () {
    test('parses OSRM routes with distance, duration, and geometry', () {
      final routes = RoutingService.parseOsrmResponse({
        'routes': [
          {
            'distance': 2500.0,
            'duration': 600.0,
            'geometry': {
              'coordinates': [
                [80.2707, 13.0827],
                [80.2800, 13.0900],
              ],
            },
          },
        ],
      });

      expect(routes, hasLength(1));
      expect(routes.first.distanceKm, equals(2.5));
      expect(routes.first.durationMinutes, equals(10));
      expect(routes.first.path.first.latitude, equals(13.0827));
      expect(routes.first.path.first.longitude, equals(80.2707));
    });
  });
}
