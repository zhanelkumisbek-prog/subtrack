import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _authService = AuthService();
  final _notificationService = NotificationService();

  bool _sendingCode = false;
  bool _resetting = false;
  bool _codeRequested = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _sendingCode = true;
      _error = null;
      _info = null;
    });

    try {
      final code = await _authService.sendPasswordResetCode(
        phoneNumber: _phoneCtrl.text,
      );
      await _notificationService.showPasswordResetCode(
        _phoneCtrl.text,
        code,
      );

      if (!mounted) return;

      setState(() {
        _codeRequested = true;
        _info =
            'Код отправлен. В офлайн-режиме приложения он приходит как локальное уведомление на это устройство.';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _sendingCode = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _resetting = true;
      _error = null;
      _info = null;
    });

    try {
      await _authService.resetPassword(
        phoneNumber: _phoneCtrl.text,
        code: _codeCtrl.text,
        newPassword: _newPasswordCtrl.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароль обновлён. Теперь можно войти с новым паролем.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _resetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Восстановление пароля')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сброс через номер телефона',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Введите номер телефона, получите код подтверждения и задайте новый пароль.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Номер телефона',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppTheme.textMuted,
                    ),
                    hintText: '+7 777 123 45 67',
                  ),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length < 10) {
                      return 'Введите корректный номер телефона';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _sendingCode ? null : _sendCode,
                    child: _sendingCode
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Отправить код'),
                  ),
                ),
                if (_codeRequested) ...[
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Код подтверждения',
                      prefixIcon: Icon(
                        Icons.verified_user_outlined,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    validator: (value) {
                      if (!_codeRequested) return null;
                      if ((value ?? '').trim().length != 6) {
                        return 'Введите 6-значный код';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordCtrl,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Новый пароль',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppTheme.textMuted,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (!_codeRequested) return null;
                      if ((value ?? '').length < 6) {
                        return 'Минимум 6 символов';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirmPassword,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Повторите пароль',
                      prefixIcon: const Icon(
                        Icons.lock_person_outlined,
                        color: AppTheme.textMuted,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (!_codeRequested) return null;
                      if (value != _newPasswordCtrl.text) {
                        return 'Пароли не совпадают';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _resetting ? null : _resetPassword,
                      child: _resetting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.background,
                              ),
                            )
                          : const Text('Сменить пароль'),
                    ),
                  ),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 16),
                  _MessageBox(
                    text: _info!,
                    background: AppTheme.accentGlow,
                    border: AppTheme.accent.withValues(alpha: 0.35),
                    foreground: AppTheme.accent,
                    icon: Icons.info_outline,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _MessageBox(
                    text: _error!,
                    background: AppTheme.dangerDim,
                    border: AppTheme.danger.withValues(alpha: 0.35),
                    foreground: AppTheme.danger,
                    icon: Icons.error_outline,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String text;
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  const _MessageBox({
    required this.text,
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
