import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/service_locator.dart';
import '../../widgets/section_header.dart';

/// Main dashboard shown after a successful login.
///
/// Layout deliberately mixes text sections, compact containers, and white cards
/// to avoid the "wall of bordered rectangles" anti-pattern.
/// All data comes from [ServiceLocator.auth.getCurrentUser] — nothing is hardcoded.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ServiceLocator.auth.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
    if (user == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile & Settings',
            onPressed: () => Navigator.of(context)
                .pushNamed(AppConstants.routeProfile)
                .then((_) => _loadUser()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUser,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          children: [
            // ── Greeting ─────────────────────────────────────────────────
            _Greeting(name: _user!.name),
            const SizedBox(height: 20),

            // ── Safety status ─────────────────────────────────────────────
            const _SafetyStatusBox(),
            const SizedBox(height: 20),

            // ── Primary action ────────────────────────────────────────────
            const _StartTripSection(),
            const SizedBox(height: 32),

            // ── Trusted person ────────────────────────────────────────────
            const SectionHeader(title: 'Trusted Person'),
            _TrustedPersonTile(
              name: _user!.trustedPerson.name,
              phone: _user!.trustedPerson.phone,
              relationship: _user!.trustedPerson.relationship,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppConstants.routeTrustedPerson)
                  .then((_) => _loadUser()),
            ),
            const SizedBox(height: 20),

            // ── Recent trips ──────────────────────────────────────────────
            const SectionHeader(title: 'Recent Trips'),
            const _RecentTripsEmpty(),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────
// Each section is a focused private widget so the build method reads as a
// linear list of content blocks.

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: const TextStyle(
            color: AppTheme.mutedGray,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: const TextStyle(
            color: AppTheme.charcoal,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

/// Compact safety status indicator.
/// Static SAFE state — no real risk engine in Phase 1.
class _SafetyStatusBox extends StatelessWidget {
  const _SafetyStatusBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.safeContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.safeBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.safeIcon,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SAFE',
                style: TextStyle(
                  color: AppTheme.safeColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'No active trip · You\'re currently safe',
                style: TextStyle(
                  color: AppTheme.safeColor.withAlpha(180),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Disabled trip CTA — clearly labelled as Phase 2.
class _StartTripSection extends StatelessWidget {
  const _StartTripSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          // Intentionally disabled — GPS monitoring is Phase 2.
          onPressed: null,
          icon: const Icon(Icons.navigation_outlined, size: 18),
          label: const Text('Start a Trip'),
        ),
        const SizedBox(height: 6),
        const Text(
          'GPS monitoring coming in Phase 2',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.mutedGray,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Tappable trusted-person summary tile.
/// Displays the stored name, relationship, and phone — nothing hardcoded.
class _TrustedPersonTile extends StatelessWidget {
  final String name;
  final String phone;
  final String relationship;
  final VoidCallback onTap;

  const _TrustedPersonTile({
    required this.name,
    required this.phone,
    required this.relationship,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  // ~8% navy tint
                  color: const Color(0x141B3A6B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people,
                  color: AppTheme.primaryNavy,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppTheme.charcoal,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$relationship · $phone',
                      style: const TextStyle(
                        color: AppTheme.mutedGray,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: AppTheme.mutedGray,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact empty state for the trip history section.
class _RecentTripsEmpty extends StatelessWidget {
  const _RecentTripsEmpty();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            const Icon(Icons.history, color: AppTheme.mutedGray, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No trips yet',
                  style: TextStyle(
                    color: AppTheme.charcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Completed trips will appear here',
                  style: TextStyle(
                    color: AppTheme.mutedGray.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
