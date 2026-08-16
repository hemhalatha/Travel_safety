import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/service_locator.dart';

/// Emergency contact screen shown when the user presses "Need Help".
///
/// Displays the stored trusted person's details and offers a confirmed
/// phone call. Never hardcodes a phone number — all data comes from storage.
class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
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
  }

  Future<void> _callTrustedPerson() async {
    final phone = _user?.trustedPerson.phone;
    if (phone == null || phone.isEmpty) return;

    // Confirmation dialog before calling.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Call ${_user!.trustedPerson.name}?',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppTheme.charcoal,
          ),
        ),
        content: Text(
          'This will call $phone.',
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
            child: const Text('Call Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final uri = Uri.parse('tel:$phone');
    try {
      final canCall = await canLaunchUrl(uri);
      if (canCall) {
        await launchUrl(uri);
      } else {
        // Web / desktop — show number prominently.
        _showCannotCallDialog(phone);
      }
    } catch (_) {
      _showCannotCallDialog(phone);
    }
  }

  void _showCannotCallDialog(String phone) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Call manually',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.charcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your device cannot make calls automatically. Please dial:',
              style: TextStyle(color: AppTheme.mutedGray),
            ),
            const SizedBox(height: 12),
            SelectableText(
              phone,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryNavy,
                letterSpacing: 1,
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

    final tp = _user?.trustedPerson;

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── SOS header ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
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
                            'Contact your trusted person for help',
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
                'TRUSTED PERSON',
                style: TextStyle(
                  color: AppTheme.primaryNavy,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0x141B3A6B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: AppTheme.primaryNavy,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tp?.name ?? '—',
                              style: const TextStyle(
                                color: AppTheme.charcoal,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tp?.relationship ?? '',
                              style: const TextStyle(
                                color: AppTheme.mutedGray,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tp?.phone ?? '—',
                              style: const TextStyle(
                                color: AppTheme.primaryNavy,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // ── Actions ───────────────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: tp != null ? _callTrustedPerson : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerColor,
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                ),
                icon: const Icon(Icons.phone, size: 18),
                label: Text(
                  tp != null
                      ? 'Call ${tp.name}'
                      : 'No trusted person set',
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
      ),
    );
  }
}
