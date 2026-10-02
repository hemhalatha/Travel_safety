import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/service_locator.dart';
import '../../widgets/section_header.dart';

/// Shows the current user's account information and their trusted person.
/// Provides a logout action that clears the session without deleting account data.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await ServiceLocator.auth.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Your account and trusted person data will be preserved.\n\n'
          'Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ServiceLocator.auth.logout();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppConstants.routeLogin,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar ─────────────────────────────────────────────
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          (_user?.name.isNotEmpty ?? false)
                              ? _user!.name[0].toUpperCase()
                              : '?',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _user?.name ?? '',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _user?.phone ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Account ────────────────────────────────────────────
                    const SectionHeader(
                      title: 'Account',
                      padding: EdgeInsets.only(bottom: 8),
                    ),
                    Card(
                      child: Column(
                        children: [
                          _InfoTile(
                            theme: theme,
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            value: _user?.name ?? '—',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                            theme: theme,
                            icon: Icons.phone,
                            label: 'Phone',
                            value: _user?.phone ?? '—',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Trusted Person ─────────────────────────────────────
                    const SectionHeader(
                      title: 'Trusted Person',
                      padding: EdgeInsets.only(bottom: 8),
                    ),
                    Card(
                      child: Column(
                        children: [
                          _InfoTile(
                            theme: theme,
                            icon: Icons.people,
                            label: 'Name',
                            value: _user?.trustedPerson.name ?? '—',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                            theme: theme,
                            icon: Icons.phone,
                            label: 'Phone',
                            value: _user?.trustedPerson.phone ?? '—',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                            theme: theme,
                            icon: Icons.favorite_border,
                            label: 'Relationship',
                            value: _user?.trustedPerson.relationship ?? '—',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── App info ───────────────────────────────────────────
                    Card(
                      child: _InfoTile(
                        theme: theme,
                        icon: Icons.info_outline,
                        label: 'Version',
                        value: '1.0.0 · Phase 1 Prototype',
                      ),
                    ),
                    const SizedBox(height: 36),

                    // ── Logout ─────────────────────────────────────────────
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
