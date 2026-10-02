class EtaService {
  static const double minutesPerKm = 1.5;

  const EtaService._();

  static int durationMinutesForDistance(double distanceKm) {
    final minutes = (distanceKm * minutesPerKm).ceil();
    return minutes < 1 ? 1 : minutes;
  }
}
