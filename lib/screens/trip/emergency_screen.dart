import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/trip_model.dart';
import '../../models/user_model.dart';
import '../../services/alert_service.dart';
import '../../services/service_locator.dart';

/// Emergency contact screen shown when the user presses "Need Help".
///
/// Displays trusted contacts and opens an SMS alert compose flow. Normal mobile
/// apps cannot send silent SMS, so the user confirms the message in their SMS app.
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  UserModel? _user;
  TripModel? _trip;
  bool _isLoading = true;
  bool _isSending = false;
  final _alertService = const AlertService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await ServiceLocator.auth.getCurrentUser();
    final trip = await ServiceLocator.trip.getActiveTrip();
    if (!mounted) return;
    setState(() {
      _user = user;
      _trip = trip;
      _isLoading = false;
    });
  }

  Future<void> _sendAlert() async {
    final user = _user;
    if (user == null || user.trustedPeople.isEmpty) return;
    final message = _alertService.buildAlertMessage(
      userName: user.name,
      trip: _trip,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Send alert message?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        content: Text(
          'This will open your SMS app with an alert for ${user.trustedPeople.length} trusted contact(s).',
          style: const TextStyle(color: AppTheme.mutedGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open SMS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSending = true);
    final sent = await _alertService.sendSmsAlert(
      trustedPeople: user.trustedPeople,
      message: message,
    );
    if (!mounted) return;
    setState(() => _isSending = false);
    if (!sent) _showCannotSendDialog(message);
  }

  void _showCannotSendDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Send manually',
          style:
              TextStyle(fontWeight: FontWeight.w700, color: AppTheme.charcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your device cannot open SMS automatically. Send this message to your trusted contacts:',
              style: TextStyle(color: AppTheme.mutedGray),
            ),
            const SizedBox(height: 12),
            SelectableText(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryNavy,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final trustedPeople = _user?.trustedPeople ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          children: [
            // ── SOS header ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.dangerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMERGENCY',
                          style: TextStyle(
                            color: AppTheme.dangerColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Send your trusted contacts an alert message',
                          style: TextStyle(
                            color: Color(0xFF9B1C1C),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Trusted person card ────────────────────────────────────────
            const Text(
              'TRUSTED CONTACTS',
              style: TextStyle(
                color: AppTheme.primaryNavy,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            for (final person in trustedPeople) ...[
              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.people, color: AppTheme.primaryNavy),
                  title: Text(person.name),
                  subtitle: Text('${person.relationship} · ${person.phone}'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 24),

            // ── Actions ───────────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed:
                  trustedPeople.isNotEmpty && !_isSending ? _sendAlert : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.surfaceWhite,
                      ),
                    )
                  : const Icon(Icons.sms_outlined, size: 18),
              label: Text(
                trustedPeople.isNotEmpty
                    ? 'Send Alert Message'
                    : 'No trusted contacts set',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel — I\'m OK'),
            ),
          ],
        ),
      ),
    );
  }
}
