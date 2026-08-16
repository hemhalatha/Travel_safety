import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/trip_model.dart';
import '../../models/user_model.dart';
import '../../services/service_locator.dart';
import '../../widgets/section_header.dart';

/// Main dashboard — dynamically reflects trip state.
///
/// No active trip  →  SAFE banner + "Start a Trip" button.
/// Active trip     →  TRIP ACTIVE/DELAYED banner + "View Trip" button.
/// Recent trips section shows actual history from [TripService].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _user;
  TripModel? _activeTrip;
  List<TripModel> _tripHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await ServiceLocator.auth.getCurrentUser();
    final activeTrip = await ServiceLocator.trip.getActiveTrip();
    final history = await ServiceLocator.trip.getHistory();

    if (!mounted) return;
    setState(() {
      _user = user;
      _activeTrip = activeTrip;
      _tripHistory = history;
      _isLoading = false;
    });

    if (user == null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushReplacementNamed(AppConstants.routeLogin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
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
                .then((_) => _loadData()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          children: [
            // ── Greeting ───────────────────────────────────────────────────
            _Greeting(name: _user!.name),
            const SizedBox(height: 20),

            // ── Safety status (dynamic) ────────────────────────────────────
            _buildStatusBanner(),
            const SizedBox(height: 20),

            // ── Primary action (dynamic) ───────────────────────────────────
            _buildActionSection(),
            const SizedBox(height: 32),

            // ── Trusted person ─────────────────────────────────────────────
            const SectionHeader(title: 'Trusted Person'),
            _TrustedPersonTile(
              name: _user!.trustedPerson.name,
              phone: _user!.trustedPerson.phone,
              relationship: _user!.trustedPerson.relationship,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppConstants.routeTrustedPerson)
                  .then((_) => _loadData()),
            ),
            const SizedBox(height: 20),

            // ── Recent trips ───────────────────────────────────────────────
            const SectionHeader(title: 'Recent Trips'),
            _buildRecentTrips(),
          ],
        ),
      ),
    );
  }

  // ── Dynamic section builders ──────────────────────────────────────────────

  Widget _buildStatusBanner() {
    if (_activeTrip == null) return const _SafeStatusBox();
    if (_activeTrip!.isDelayed) {
      return _TripDelayedBox(destination: _activeTrip!.destination);
    }
    return _TripActiveBox(
      destination: _activeTrip!.destination,
      remainingMinutes: _activeTrip!.remainingMinutes,
    );
  }

  Widget _buildActionSection() {
    if (_activeTrip == null) {
      // No active trip — enable Start Trip.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context)
                .pushNamed(AppConstants.routeTripSetup)
                .then((_) => _loadData()),
            icon: const Icon(Icons.navigation_outlined, size: 18),
            label: const Text('Start a Trip'),
          ),
        ],
      );
    }
    // Active trip — show View Trip.
    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context)
          .pushNamed(AppConstants.routeActiveTrip)
          .then((_) => _loadData()),
      icon: const Icon(Icons.visibility_outlined, size: 18),
      label: const Text('View Trip'),
    );
  }

  Widget _buildRecentTrips() {
    if (_tripHistory.isEmpty) return const _RecentTripsEmpty();
    return Column(
      children: _tripHistory
          .take(5)
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TripHistoryItem(trip: t),
              ))
          .toList(),
    );
  }
}

// ── Static status boxes ───────────────────────────────────────────────────────

class _SafeStatusBox extends StatelessWidget {
  const _SafeStatusBox();

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

class _TripActiveBox extends StatelessWidget {
  final String destination;
  final int remainingMinutes;

  const _TripActiveBox({
    required this.destination,
    required this.remainingMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = remainingMinutes >= 0
        ? '$remainingMinutes min left'
        : '${-remainingMinutes} min overdue';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.primaryNavy,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRIP ACTIVE',
                  style: TextStyle(
                    color: AppTheme.primaryNavy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$destination · $remaining',
                  style: TextStyle(
                    color: AppTheme.primaryNavy.withAlpha(180),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripDelayedBox extends StatelessWidget {
  final String destination;
  const _TripDelayedBox({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppTheme.warningColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TRIP DELAYED',
                  style: TextStyle(
                    color: AppTheme.warningColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Trip to $destination has exceeded expected time',
                  style: TextStyle(
                    color: AppTheme.warningColor.withAlpha(200),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Other private widgets ─────────────────────────────────────────────────────

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
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
              const Icon(Icons.chevron_right,
                  color: AppTheme.mutedGray, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _TripHistoryItem extends StatelessWidget {
  final TripModel trip;
  const _TripHistoryItem({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.route, color: AppTheme.primaryNavy, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.destination,
                    style: const TextStyle(
                      color: AppTheme.charcoal,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(trip.startTime),
                    style: const TextStyle(
                      color: AppTheme.mutedGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(status: trip.status),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 0) return 'Today · $time';
    if (diff.inDays == 1) return 'Yesterday · $time';
    return '${dt.day}/${dt.month}/${dt.year} · $time';
  }
}

class _StatusPill extends StatelessWidget {
  final TripStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      TripStatus.active => ('Active', AppTheme.primaryNavy, const Color(0xFFEFF6FF)),
      TripStatus.completed => ('Done', AppTheme.safeColor, AppTheme.safeContainer),
      TripStatus.cancelled => ('Cancelled', AppTheme.mutedGray, AppTheme.borderLight),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
