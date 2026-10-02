import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class PlaceSuggestion {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const PlaceSuggestion({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  String get displayAddress => address.isNotEmpty ? address : name;
}

class GeocodingService {
  static const String _endpoint = 'https://nominatim.openstreetmap.org/search';

  final http.Client _client;

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  void dispose() => _client.close();

  Future<List<PlaceSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'q': trimmed,
        'format': 'jsonv2',
        'limit': '5',
        'addressdetails': '1',
      },
    );

    try {
      final response = await _client.get(
        uri,
        headers: const {'User-Agent': AppConstants.networkUserAgent},
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return const [];
      }
      return parseNominatimResponse(jsonDecode(response.body));
    } catch (_) {
      return const [];
    }
  }

  static List<PlaceSuggestion> parseNominatimResponse(Object? payload) {
    if (payload is! List) return const [];

    final suggestions = <PlaceSuggestion>[];
    for (final item in payload) {
      if (item is! Map<String, dynamic>) continue;
      final latitude = double.tryParse(item['lat']?.toString() ?? '');
      final longitude = double.tryParse(item['lon']?.toString() ?? '');
      final displayName = item['display_name']?.toString().trim();
      if (latitude == null ||
          longitude == null ||
          displayName == null ||
          displayName.isEmpty) {
        continue;
      }

      suggestions.add(
        PlaceSuggestion(
          name: _shortName(item, displayName),
          address: displayName,
          latitude: latitude,
          longitude: longitude,
        ),
      );
    }
    return suggestions;
  }

  static String _shortName(Map<String, dynamic> item, String displayName) {
    final named = item['name']?.toString().trim();
    if (named != null && named.isNotEmpty) return named;
    return displayName.split(',').first.trim();
  }
}
