import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/trip/active_trip_screen.dart';
import '../screens/trip/emergency_screen.dart';
import '../screens/trip/trip_setup_screen.dart';
import '../screens/trusted_person/trusted_person_screen.dart';

/// Centralized route factory.
///
/// All route name strings live in [AppConstants] to prevent magic strings.
class AppRouter {
  AppRouter._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // ── Phase 1 routes ────────────────────────────────────────────────────
      case AppConstants.routeSplash:
        return _fadeRoute(const SplashScreen());
      case AppConstants.routeLogin:
        return MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case AppConstants.routeRegister:
        return MaterialPageRoute<void>(
          builder: (_) => const RegistrationScreen(),
          settings: settings,
        );
      case AppConstants.routeHome:
        return _fadeRoute(const HomeScreen());
      case AppConstants.routeTrustedPerson:
        return MaterialPageRoute<void>(
          builder: (_) => const TrustedPersonScreen(),
          settings: settings,
        );
      case AppConstants.routeProfile:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );

      // ── Phase 2 routes ────────────────────────────────────────────────────
      case AppConstants.routeTripSetup:
        return MaterialPageRoute<void>(
          builder: (_) => const TripSetupScreen(),
          settings: settings,
        );
      case AppConstants.routeActiveTrip:
        return MaterialPageRoute<void>(
          builder: (_) => const ActiveTripScreen(),
          settings: settings,
        );
      case AppConstants.routeEmergency:
        return MaterialPageRoute<void>(
          builder: (_) => const EmergencyScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }

  /// Fade transition — used for top-level screens (splash → home).
  static PageRouteBuilder<void> _fadeRoute(Widget page) {
    return PageRouteBuilder<void>(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
