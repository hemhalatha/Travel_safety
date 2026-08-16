import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_text_field.dart';

/// Trip setup form — collects destination and expected duration, then starts
/// the trip and pops back to Home (which reloads to show TRIP ACTIVE state).
class TripSetupScreen extends StatefulWidget {
  const TripSetupScreen({super.key});

  @override
  State<TripSetupScreen> createState() => _TripSetupScreenState();
}

class _TripSetupScreenState extends State<TripSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationCtrl = TextEditingController();
  int _selectedMinutes = 30;
  bool _isStarting = false;

  static const List<(int, String)> _durationOptions = [
    (15, '15 min'),
    (30, '30 min'),
    (45, '45 min'),
    (60, '1 hour'),
    (90, '1 hr 30 min'),
    (120, '2 hours'),
    (180, '3 hours'),
  ];

  @override
  void dispose() {
    _destinationCtrl.dispose();
    super.dispose();
  }

  Future<void> _startTrip() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isStarting = true);

    // Request location permission in background — trip continues regardless.
    ServiceLocator.location.requestPermission();

    await ServiceLocator.trip.startTrip(
      destination: _destinationCtrl.text.trim(),
      durationMinutes: _selectedMinutes,
    );

    if (!mounted) return;
    // Pop back to Home; Home's .then() callback will reload and show TRIP ACTIVE.
    Navigator.of(context).pop();
    // Navigate to active trip screen immediately.
    Navigator.of(context).pushNamed(AppConstants.routeActiveTrip);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Where are you going?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.charcoal,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enter your destination and expected travel time.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.mutedGray),
                ),
                const SizedBox(height: 28),

                // Destination
                AppTextField(
                  controller: _destinationCtrl,
                  label: 'Destination',
                  hint: 'e.g. Chennai Central Station',
                  prefixIcon: Icons.place_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a destination'
                      : null,
                ),
                const SizedBox(height: 24),

                // Duration picker
                Text(
                  'EXPECTED DURATION',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                _DurationPicker(
                  options: _durationOptions,
                  selectedMinutes: _selectedMinutes,
                  onChanged: (v) => setState(() => _selectedMinutes = v),
                ),
                const SizedBox(height: 8),
                Text(
                  'A safety check will be shown if your trip runs longer than expected.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.mutedGray),
                ),
                const SizedBox(height: 32),

                // Start button
                ElevatedButton.icon(
                  onPressed: _isStarting ? null : _startTrip,
                  icon: _isStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.surfaceWhite,
                          ),
                        )
                      : const Icon(Icons.navigation_outlined, size: 18),
                  label: Text(_isStarting ? 'Starting…' : 'Start Trip'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Duration picker ───────────────────────────────────────────────────────────

class _DurationPicker extends StatelessWidget {
  final List<(int, String)> options;
  final int selectedMinutes;
  final ValueChanged<int> onChanged;

  const _DurationPicker({
    required this.options,
    required this.selectedMinutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final (minutes, label) = option;
        final isSelected = minutes == selectedMinutes;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onChanged(minutes),
          selectedColor: AppTheme.primaryNavy,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.surfaceWhite : AppTheme.charcoal,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          backgroundColor: AppTheme.surfaceWhite,
          side: BorderSide(
            color: isSelected ? AppTheme.primaryNavy : AppTheme.borderLight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }).toList(),
    );
  }
}
