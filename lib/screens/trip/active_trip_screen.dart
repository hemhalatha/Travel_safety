import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/trip_model.dart';
import '../../services/location_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/section_header.dart';

/// Live trip monitoring screen shown during an active trip.
///
/// Updates every second via [Timer.periodic] to show the countdown.
/// Detects delayed state and shows a safety check dialog.
/// Location is best-effort — the trip works even if GPS is unavailable.
class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  TripModel? _trip;
  bool _isLoading = true;
  bool _isEnding = false;

  // Location state
  Position? _startPosition;
  Position? _currentPosition;
  String _locationStatus = 'Getting location…';

  // Safety timer state
  Timer? _ticker;
  bool _safetyDialogShowing = false;
  DateTime? _nextSafetyCheckAt;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadTrip();
    _startLocation();
    // Tick every second to update countdown and check for delayed state.
    _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> _loadTrip() async {
    final trip = await ServiceLocator.trip.getActiveTrip();
    if (!mounted) return;
    setState(() {
      _trip = trip;
      _isLoading = false;
    });
  }

  Future<void> _startLocation() async {
    final granted = await ServiceLocator.location.requestPermission();
    if (!mounted) return;

    if (!granted) {
      setState(() => _locationStatus = 'Location unavailable');
      return;
    }

    setState(() => _locationStatus = 'Getting location…');
    final position = await ServiceLocator.location.getCurrentPosition();
    if (!mounted) return;

    if (position == null) {
      setState(() => _locationStatus = 'Location unavailable');
      return;
    }

    setState(() {
      _startPosition = position;
      _currentPosition = position;
      _locationStatus = 'Location tracked';
    });
  }

  // ── Timer callback ─────────────────────────────────────────────────────────

  void _onTick(Timer timer) {
    if (!mounted) return;
    setState(() {}); // Rebuild to update countdown.

    if (_trip == null || !_trip!.isActive || _safetyDialogShowing) return;

    // Show safety check when trip is delayed.
    if (_trip!.isDelayed) {
      final now = DateTime.now();
      final shouldShow =
          _nextSafetyCheckAt == null || now.isAfter(_nextSafetyCheckAt!);
      if (shouldShow) {
        _safetyDialogShowing = true;
        // Schedule after current frame to avoid showing mid-build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showSafetyCheck();
        });
      }
    }

    // Refresh location every 60 seconds.
    if (_startPosition != null &&
        timer.tick % 60 == 0) {
      _refreshLocation();
    }
  }

  Future<void> _refreshLocation() async {
    final position = await ServiceLocator.location.getCurrentPosition();
    if (!mounted || position == null) return;
    setState(() => _currentPosition = position);
  }

  // ── Safety check dialog ────────────────────────────────────────────────────

  Future<void> _showSafetyCheck() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.warningColor,
          size: 36,
        ),
        title: const Text(
          'Are you safe?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        content: Text(
          'Your trip to ${_trip?.destination ?? 'your destination'} has exceeded the expected duration.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.mutedGray),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("I'm Safe"),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.dangerColor,
                  side: const BorderSide(color: AppTheme.dangerColor),
                ),
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Need Help'),
              ),
            ],
          ),
        ],
      ),
    );

    if (!mounted) return;
    _safetyDialogShowing = false;

    if (result == true) {
      // Safe — next check in 15 minutes.
      _nextSafetyCheckAt =
          DateTime.now().add(const Duration(minutes: 15));
    } else if (result == false) {
      // Needs help — open emergency screen.
      _nextSafetyCheckAt =
          DateTime.now().add(const Duration(minutes: 30));
      Navigator.of(context).pushNamed(AppConstants.routeEmergency);
    } else {
      // Dismissed via back — check again in 5 minutes.
      _nextSafetyCheckAt =
          DateTime.now().add(const Duration(minutes: 5));
    }
  }

  // ── End trip ───────────────────────────────────────────────────────────────

  Future<void> _endTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'End Trip?',
          style: TextStyle(
              fontWeight: FontWeight.w700, color: AppTheme.charcoal),
        ),
        content: const Text(
          'Your trip will be saved to history.',
          style: TextStyle(color: AppTheme.mutedGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue Trip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isEnding = true);
    _ticker?.cancel();

    await ServiceLocator.trip.endTrip();
    if (!mounted) return;

    // Return to home screen; home will reload via .then() callback.
    Navigator.of(context).pop();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatCountdown() {
    if (_trip == null) return '—';
    final remaining =
        Duration(minutes: _trip!.durationMinutes) -
            DateTime.now().difference(_trip!.startTime);

    if (remaining.isNegative) {
      final overdue = remaining.abs();
      final h = overdue.inHours;
      final m = overdue.inMinutes % 60;
      final s = overdue.inSeconds % 60;
      if (h > 0) return '${h}h ${m}m overdue';
      if (m > 0) return '${m}m ${s}s overdue';
      return '${s}s overdue';
    }

    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  String _formatElapsed() {
    if (_trip == null) return '—';
    final elapsed = DateTime.now().difference(_trip!.startTime);
    final h = elapsed.inHours;
    final m = elapsed.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m elapsed';
    return '${m}m ${elapsed.inSeconds % 60}s elapsed';
  }

  String _formatStartTime() {
    if (_trip == null) return '—';
    final t = _trip!.startTime;
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _distanceTravelled() {
    if (_startPosition == null || _currentPosition == null) return '—';
    final km = LocationService.distanceKm(_startPosition!, _currentPosition!);
    return km < 1
        ? '${(km * 1000).round()} m'
        : '${km.toStringAsFixed(1)} km';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Trip')),
        body: const Center(
          child: Text(
            'No active trip found.',
            style: TextStyle(color: AppTheme.mutedGray),
          ),
        ),
      );
    }

    final isDelayed = _trip!.isDelayed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Trip'),
        actions: [
          TextButton(
            onPressed: _isEnding ? null : _endTrip,
            child: Text(
              'End Trip',
              style: TextStyle(
                color: _isEnding ? AppTheme.mutedGray : AppTheme.dangerColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        children: [
          // ── Status ───────────────────────────────────────────────────────
          _StatusBanner(isDelayed: isDelayed),
          const SizedBox(height: 20),

          // ── Countdown ────────────────────────────────────────────────────
          _CountdownCard(
            countdown: _formatCountdown(),
            elapsed: _formatElapsed(),
            isDelayed: isDelayed,
          ),
          const SizedBox(height: 20),

          // ── Trip details ─────────────────────────────────────────────────
          const SectionHeader(title: 'Trip Details'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.place_outlined,
                    label: 'Destination',
                    value: _trip!.destination,
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.schedule_outlined,
                    label: 'Started at',
                    value: _formatStartTime(),
                  ),
                  const Divider(height: 20),
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Expected duration',
                    value: '${_trip!.durationMinutes} min',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Location ─────────────────────────────────────────────────────
          const SectionHeader(title: 'Location'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.gps_fixed,
                    label: 'GPS',
                    value: _locationStatus,
                  ),
                  if (_startPosition != null) ...[
                    const Divider(height: 20),
                    _DetailRow(
                      icon: Icons.route_outlined,
                      label: 'Distance travelled',
                      value: _distanceTravelled(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Emergency shortcut ────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppConstants.routeEmergency),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.dangerColor,
              side: const BorderSide(color: AppTheme.dangerColor),
            ),
            icon: const Icon(Icons.phone, size: 16),
            label: const Text('Contact Trusted Person'),
          ),
        ],
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final bool isDelayed;
  const _StatusBanner({required this.isDelayed});

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isDelayed ? const Color(0xFFFFF8F0) : const Color(0xFFEFF6FF);
    final borderColor =
        isDelayed ? const Color(0xFFFDE68A) : const Color(0xFFBFDBFE);
    final dotColor =
        isDelayed ? AppTheme.warningColor : AppTheme.primaryNavy;
    final label = isDelayed ? 'TRIP DELAYED' : 'TRIP ACTIVE';
    final subtitle = isDelayed
        ? 'Your trip has exceeded the expected time'
        : 'Monitoring your journey';
    final textColor =
        isDelayed ? AppTheme.warningColor : AppTheme.primaryNavy;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final String countdown;
  final String elapsed;
  final bool isDelayed;

  const _CountdownCard({
    required this.countdown,
    required this.elapsed,
    required this.isDelayed,
  });

  @override
  Widget build(BuildContext context) {
    final countdownColor =
        isDelayed ? AppTheme.warningColor : AppTheme.primaryNavy;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          children: [
            Text(
              isDelayed ? 'Overdue by' : 'Time remaining',
              style: const TextStyle(
                color: AppTheme.mutedGray,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              countdown,
              style: TextStyle(
                color: countdownColor,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              elapsed,
              style: const TextStyle(
                color: AppTheme.mutedGray,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.mutedGray),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.mutedGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.charcoal,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
