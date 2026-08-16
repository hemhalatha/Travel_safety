/// Application-wide string constants and route names.
/// Centralising these avoids magic strings scattered across the codebase.
library;

class AppConstants {
  AppConstants._();

  static const String appName = 'Travel Safety';
  static const String tagline = 'Your journey, always protected.';

  // ---------------------------------------------------------------------------
  // Named routes
  // ---------------------------------------------------------------------------
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeTrustedPerson = '/trusted-person';
  static const String routeProfile = '/profile';
}
