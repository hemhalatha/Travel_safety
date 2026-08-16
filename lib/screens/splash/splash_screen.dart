import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../services/service_locator.dart';

/// Entry point shown every time the app launches.
///
/// Displays brand identity for a brief moment then routes to:
/// - [HomeScreen] if a valid session exists
/// - [LoginScreen] if the user is registered but not logged in
/// - [RegistrationScreen] if no account exists on this device
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final isLoggedIn = await ServiceLocator.auth.isLoggedIn();
    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
      return;
    }

    final hasUser = await ServiceLocator.auth.hasRegisteredUser();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      hasUser ? AppConstants.routeLogin : AppConstants.routeRegister,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shield icon
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: onPrimary.withAlpha(26),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.shield, size: 44, color: onPrimary),
                ),
                const SizedBox(height: 28),

                // App name
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),

                // Tagline
                Text(
                  AppConstants.tagline,
                  style: TextStyle(
                    color: onPrimary.withAlpha(204),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 80),

                // Spinner
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: onPrimary.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
