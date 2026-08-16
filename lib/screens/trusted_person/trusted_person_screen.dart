import 'package:flutter/material.dart';

import '../../models/trusted_person_model.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_text_field.dart';

/// Displays the current trusted person's details and allows editing.
///
/// Changes are validated and persisted to local storage via [AuthService].
/// The phone number shown is whatever the user entered during registration
/// or a subsequent edit — nothing is hardcoded.
class TrustedPersonScreen extends StatefulWidget {
  const TrustedPersonScreen({super.key});

  @override
  State<TrustedPersonScreen> createState() => _TrustedPersonScreenState();
}

class _TrustedPersonScreenState extends State<TrustedPersonScreen> {
  TrustedPersonModel? _current;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = await ServiceLocator.auth.getCurrentUser();
    if (!mounted) return;
    final tp = user?.trustedPerson;
    setState(() {
      _current = tp;
      _isLoading = false;
    });
    if (tp != null) {
      _nameCtrl.text = tp.name;
      _phoneCtrl.text = tp.phone;
      _relationshipCtrl.text = tp.relationship;
    }
  }

  void _startEditing() => setState(() => _isEditing = true);

  void _cancelEditing() {
    // Restore controllers to current saved values.
    if (_current != null) {
      _nameCtrl.text = _current!.name;
      _phoneCtrl.text = _current!.phone;
      _relationshipCtrl.text = _current!.relationship;
    }
    setState(() => _isEditing = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = TrustedPersonModel(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      relationship: _relationshipCtrl.text.trim(),
    );

    await ServiceLocator.auth.updateTrustedPerson(updated);

    if (!mounted) return;
    setState(() {
      _current = updated;
      _isEditing = false;
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trusted person updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Person'),
        actions: [
          if (!_isEditing && !_isLoading)
            TextButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              onPressed: _startEditing,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people,
                            size: 40,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (!_isEditing) ...[
                        // ── View mode ──────────────────────────────────────
                        _DetailRow(
                          theme: theme,
                          icon: Icons.person_outline,
                          label: 'Name',
                          value: _current?.name ?? '—',
                        ),
                        const Divider(height: 32),
                        _DetailRow(
                          theme: theme,
                          icon: Icons.phone,
                          label: 'Phone Number',
                          value: _current?.phone ?? '—',
                        ),
                        const Divider(height: 32),
                        _DetailRow(
                          theme: theme,
                          icon: Icons.favorite_border,
                          label: 'Relationship',
                          value: _current?.relationship ?? '—',
                        ),
                        const SizedBox(height: 32),
                        _InfoNote(
                          theme: theme,
                          message:
                              'This person can be contacted during a safety escalation.',
                        ),
                      ] else ...[
                        // ── Edit mode ──────────────────────────────────────
                        Text(
                          'Update Details',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          controller: _nameCtrl,
                          label: 'Name',
                          prefixIcon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Name is required'
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _phoneCtrl,
                          label: 'Phone Number',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          textInputAction: TextInputAction.next,
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _relationshipCtrl,
                          label: 'Relationship',
                          hint: 'e.g. Mother, Spouse, Friend',
                          prefixIcon: Icons.favorite_border,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Relationship is required'
                                  : null,
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5),
                                )
                              : const Text('Save Changes'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _cancelEditing,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (digits.length < 7 || !RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 14),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  final ThemeData theme;
  final String message;

  const _InfoNote({required this.theme, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 18, color: theme.colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
