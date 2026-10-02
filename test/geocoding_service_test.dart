import 'package:flutter_test/flutter_test.dart';
import 'package:travel_safety_app/services/geocoding_service.dart';

void main() {
  group('GeocodingService', () {
    test('parses Nominatim search results into place suggestions', () {
      final suggestions = GeocodingService.parseNominatimResponse([
        {
          'name': 'Chennai Central',
          'display_name': 'Chennai Central, Chennai, Tamil Nadu, India',
          'lat': '13.0824',
          'lon': '80.2755',
        },
      ]);

      expect(suggestions, hasLength(1));
      expect(suggestions.first.name, equals('Chennai Central'));
      expect(suggestions.first.latitude, equals(13.0824));
      expect(suggestions.first.longitude, equals(80.2755));
    });
  });
}
