import 'package:flutter_test/flutter_test.dart';
import 'package:travel_safety_app/services/eta_service.dart';

void main() {
  group('EtaService', () {
    test('calculates duration at one minute thirty seconds per kilometre', () {
      expect(EtaService.durationMinutesForDistance(10), equals(15));
      expect(EtaService.durationMinutesForDistance(1), equals(2));
      expect(EtaService.durationMinutesForDistance(0), equals(1));
    });
  });
}
