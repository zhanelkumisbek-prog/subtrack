import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _authService = AuthService();

  bool _notificationsEnabled = true;
  bool _saving = false;
  String _currency = 'USD';
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.user.displayName ?? '';
    _phoneCtrl.text = widget.user.phoneNumber ?? '';
    _notificationsEnabled = widget.user.notificationsEnabled;
    _currency = widget.user.currency ?? 'USD';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updated = await _authService.updateProfile(
        uid: widget.user.uid,
        displayName: _nameCtrl.text,
        phoneNumber: _phoneCtrl.text,
        currency: _currency,
        notificationsEnabled: _notificationsEnabled,
      );

      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppTheme.textMuted),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Введите имя';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.user.email,
                  enabled: false,
                  style: const TextStyle(color: AppTheme.textMuted),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        Icon(Icons.email_outlined, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Номер телефона',
                    prefixIcon:
                        Icon(Icons.phone_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length < 10) {
                      return 'Введите корректный номер';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text('Валюта', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ['USD', 'KZT', 'RUB', 'EUR'].map((currency) {
                    final selected = _currency == currency;
                    return ChoiceChip(
                      label: Text(currency),
                      selected: selected,
                      onSelected: (_) => setState(() => _currency = currency),
                      selectedColor: AppTheme.accentGlow,
                      backgroundColor: AppTheme.surfaceElevated,
                      labelStyle: TextStyle(
                        color:
                            selected ? AppTheme.accent : AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: selected ? AppTheme.accent : AppTheme.border,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Уведомления'),
                  subtitle: const Text('Напоминания о ближайших списаниях'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerDim,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.danger),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.background,
                            ),
                          )
                        : const Text('Сохранить изменения'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
