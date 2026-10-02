import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip_model.dart';

class RouteOption {
  final double distanceKm;
  final int durationMinutes;
  final List<TripCoordinate> path;

  const RouteOption({
    required this.distanceKm,
    required this.durationMinutes,
    required this.path,
  });
}

class RoutingService {
  static const String _endpoint =
      'https://router.project-osrm.org/route/v1/driving';

  final http.Client _client;

  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  void dispose() => _client.close();

  Future<List<RouteOption>> routes({
    required double startLatitude,
    required double startLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
  }) async {
    final uri = Uri.parse(
      '$_endpoint/$startLongitude,$startLatitude;'
      '$destinationLongitude,$destinationLatitude',
    ).replace(
      queryParameters: {
        'overview': 'full',
        'geometries': 'geojson',
        'alternatives': 'true',
      },
    );

    try {
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      return parseOsrmResponse(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (_) {
      return const [];
    }
  }

  static List<RouteOption> parseOsrmResponse(Map<String, dynamic> payload) {
    final routes = payload['routes'];
    if (routes is! List) return const [];

    final result = <RouteOption>[];
    for (final route in routes) {
      if (route is! Map<String, dynamic>) continue;

      final distanceMeters = (route['distance'] as num?)?.toDouble();
      final durationSeconds = (route['duration'] as num?)?.toDouble();
      final geometry = route['geometry'];
      final coordinates =
          geometry is Map<String, dynamic> ? geometry['coordinates'] : null;
      if (distanceMeters == null ||
          durationSeconds == null ||
          coordinates is! List) {
        continue;
      }

      final path = <TripCoordinate>[];
      for (final coordinate in coordinates) {
        if (coordinate is! List || coordinate.length < 2) continue;
        final longitude = (coordinate[0] as num?)?.toDouble();
        final latitude = (coordinate[1] as num?)?.toDouble();
        if (latitude == null || longitude == null) continue;
        path.add(TripCoordinate(latitude: latitude, longitude: longitude));
      }

      result.add(
        RouteOption(
          distanceKm: distanceMeters / 1000,
          durationMinutes: (durationSeconds / 60).ceil(),
          path: path,
        ),
      );
    }

    return result;
  }
}
