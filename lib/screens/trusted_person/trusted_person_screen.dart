import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../models/trusted_person_model.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_text_field.dart';

class TrustedPersonScreen extends StatefulWidget {
  const TrustedPersonScreen({super.key});

  @override
  State<TrustedPersonScreen> createState() => _TrustedPersonScreenState();
}

class _TrustedPersonScreenState extends State<TrustedPersonScreen> {
  final List<TrustedPersonModel> _trustedPeople = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await ServiceLocator.auth.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _trustedPeople
        ..clear()
        ..addAll(user?.trustedPeople ?? const []);
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await ServiceLocator.auth.updateTrustedPeople(_trustedPeople);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trusted contacts updated')),
    );
  }

  Future<void> _openEditor({TrustedPersonModel? person, int? index}) async {
    final updated = await showModalBottomSheet<TrustedPersonModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TrustedPersonEditor(person: person),
    );
    if (updated == null) return;
    setState(() {
      if (index == null) {
        _trustedPeople.add(updated);
      } else {
        _trustedPeople[index] = updated;
      }
    });
  }

  void _removeAt(int index) {
    setState(() => _trustedPeople.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            const _InfoNote(
              message:
                  'Emergency alerts are sent as SMS drafts to every trusted contact.',
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _trustedPeople.length; i++) ...[
              Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.people, color: AppTheme.primaryNavy),
                  title: Text(_trustedPeople[i].name),
                  subtitle: Text(
                    '${_trustedPeople[i].relationship} · ${_trustedPeople[i].phone}',
                  ),
                  onTap: () => _openEditor(person: _trustedPeople[i], index: i),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove',
                    onPressed: () => _removeAt(i),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrustedPersonEditor extends StatefulWidget {
  final TrustedPersonModel? person;

  const _TrustedPersonEditor({this.person});

  @override
  State<_TrustedPersonEditor> createState() => _TrustedPersonEditorState();
}

class _TrustedPersonEditorState extends State<_TrustedPersonEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _relationshipCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.person?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.person?.phone ?? '');
    _relationshipCtrl =
        TextEditingController(text: widget.person?.relationship ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relationshipCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TrustedPersonModel(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        relationship: _relationshipCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameCtrl,
              label: 'Name',
              prefixIcon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _phoneCtrl,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              textInputAction: TextInputAction.next,
              validator: _validatePhone,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _relationshipCtrl,
              label: 'Relationship',
              hint: 'e.g. Mother, Friend',
              prefixIcon: Icons.favorite_border,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Relationship is required'
                  : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(
                  widget.person == null ? 'Add Contact' : 'Update Contact'),
            ),
          ],
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

class _InfoNote extends StatelessWidget {
  final String message;

  const _InfoNote({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
