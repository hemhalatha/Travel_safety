import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/trusted_person_model.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_text_field.dart';

/// Two-step account creation:
///   Step 1 — Your Details (name, phone, password, confirm)
///   Step 2 — Trusted Person (name, phone, relationship)
///
/// All fields and validation logic are preserved exactly.
/// Only the layout and step indicator have been refined.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _step = 0;

  // Step 1
  final _userFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 2
  final _trustedFormKey = GlobalKey<FormState>();
  final _trustedNameCtrl = TextEditingController();
  final _trustedPhoneCtrl = TextEditingController();
  final _relationshipCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _trustedNameCtrl.dispose();
    _trustedPhoneCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (!_userFormKey.currentState!.validate()) return;
    setState(() {
      _step = 1;
      _errorMessage = null;
    });
  }

  void _goToStep1() => setState(() {
        _step = 0;
        _errorMessage = null;
      });

  Future<void> _register() async {
    if (!_trustedFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final trustedPerson = TrustedPersonModel(
      name: _trustedNameCtrl.text.trim(),
      phone: _trustedPhoneCtrl.text.trim(),
      relationship: _relationshipCtrl.text.trim(),
    );

    final result = await ServiceLocator.auth.register(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text,
      trustedPerson: trustedPerson,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
    } else {
      setState(() => _errorMessage = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: _goToStep1,
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _StepDot(step: 0, current: _step),
                const SizedBox(width: 6),
                _StepDot(step: 1, current: _step),
                const SizedBox(width: 12),
                Text(
                  _step == 0 ? 'Your Details' : 'Trusted Person',
                  style: const TextStyle(
                    color: AppTheme.mutedGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _step == 0
                ? _UserDetailsStep(
                    key: const ValueKey('step1'),
                    formKey: _userFormKey,
                    nameCtrl: _nameCtrl,
                    phoneCtrl: _phoneCtrl,
                    passwordCtrl: _passwordCtrl,
                    confirmCtrl: _confirmCtrl,
                    obscurePassword: _obscurePassword,
                    obscureConfirm: _obscureConfirm,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onToggleConfirm: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    onNext: _goToStep2,
                    onGoToLogin: () => Navigator.of(context)
                        .pushReplacementNamed(AppConstants.routeLogin),
                  )
                : _TrustedPersonStep(
                    key: const ValueKey('step2'),
                    formKey: _trustedFormKey,
                    nameCtrl: _trustedNameCtrl,
                    phoneCtrl: _trustedPhoneCtrl,
                    relationshipCtrl: _relationshipCtrl,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    onRegister: _register,
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Animated step dot ─────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final int step;
  final int current;

  const _StepDot({required this.step, required this.current});

  @override
  Widget build(BuildContext context) {
    final isActive = step == current;
    final isDone = step < current;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: (isActive || isDone)
            ? AppTheme.primaryNavy
            : AppTheme.borderLight,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
    );
  }
}

// ── Step 1 — Your Details ─────────────────────────────────────────────────────

class _UserDetailsStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onNext;
  final VoidCallback onGoToLogin;

  const _UserDetailsStep({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onNext,
    required this.onGoToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tell us about yourself',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedGray,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: nameCtrl,
            label: 'Full Name',
            hint: 'e.g. Jane Smith',
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Full name is required'
                : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: phoneCtrl,
            label: 'Phone Number',
            hint: '+91 9876543210',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            textInputAction: TextInputAction.next,
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: passwordCtrl,
            label: 'Password',
            hint: 'Min. 6 characters',
            obscureText: obscurePassword,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined, size: 20),
              tooltip: obscurePassword ? 'Show password' : 'Hide password',
              onPressed: onTogglePassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: confirmCtrl,
            label: 'Confirm Password',
            obscureText: obscureConfirm,
            prefixIcon: Icons.lock_outline,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              icon: Icon(obscureConfirm
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined, size: 20),
              tooltip: obscureConfirm ? 'Show password' : 'Hide password',
              onPressed: onToggleConfirm,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onNext,
            child: const Text('Next: Trusted Person'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.mutedGray),
              ),
              TextButton(
                onPressed: onGoToLogin,
                child: const Text('Sign In'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (digits.length < 7 || !RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}

// ── Step 2 — Trusted Person ───────────────────────────────────────────────────

class _TrustedPersonStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController relationshipCtrl;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRegister;

  const _TrustedPersonStep({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.relationshipCtrl,
    required this.isLoading,
    required this.errorMessage,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trusted Person',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.charcoal,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Who should we contact if something goes wrong?',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.mutedGray),
          ),
          const SizedBox(height: 14),

          // Info note
          _InfoNote(
            message:
                'This person can be contacted during a safety escalation. Enter a real phone number.',
            color: theme.colorScheme.primaryContainer,
            onColor: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 20),

          AppTextField(
            controller: nameCtrl,
            label: "Trusted Person's Name",
            hint: 'e.g. John Smith',
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: phoneCtrl,
            label: 'Phone Number',
            hint: '+91 9876543210',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            textInputAction: TextInputAction.next,
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: relationshipCtrl,
            label: 'Relationship',
            hint: 'e.g. Mother, Spouse, Friend',
            prefixIcon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                (v == null || v.trim().isEmpty)
                    ? 'Relationship is required'
                    : null,
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 14),
            _InfoNote(
              message: errorMessage!,
              color: theme.colorScheme.errorContainer,
              onColor: theme.colorScheme.onErrorContainer,
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : onRegister,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.surfaceWhite,
                    ),
                  )
                : const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (digits.length < 7 || !RegExp(r'^\d+$').hasMatch(digits)) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}

// ── Shared sub-widget ─────────────────────────────────────────────────────────

class _InfoNote extends StatelessWidget {
  final String message;
  final Color color;
  final Color onColor;

  const _InfoNote({
    required this.message,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: onColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: onColor),
            ),
          ),
        ],
      ),
    );
  }
}
