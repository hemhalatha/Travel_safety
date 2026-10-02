import 'package:url_launcher/url_launcher.dart';

import '../models/trusted_person_model.dart';
import '../models/trip_model.dart';

class AlertService {
  const AlertService();

  String buildAlertMessage({
    required String userName,
    required TripModel? trip,
  }) {
    final destination = trip?.destination ?? 'their destination';
    final location = trip?.hasDestinationCoordinates == true
        ? ' Destination: ${trip!.destinationLatitude!.toStringAsFixed(5)}, '
            '${trip.destinationLongitude!.toStringAsFixed(5)}.'
        : '';
    return 'Travel Safety alert: $userName may need help on the trip to '
        '$destination.$location Please contact them immediately.';
  }

  Future<bool> sendSmsAlert({
    required List<TrustedPersonModel> trustedPeople,
    required String message,
  }) async {
    if (trustedPeople.isEmpty) return false;
    final phones = trustedPeople.map((p) => p.phone.trim()).join(',');
    final uri = Uri(
      scheme: 'sms',
      path: phones,
      queryParameters: {'body': message},
    );
    try {
      if (!await canLaunchUrl(uri)) return false;
      return launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}
