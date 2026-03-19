import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AppUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<AppUser?>(
      stream: authService.authStateChanges(),
      initialData: user,
      builder: (context, snapshot) {
        final currentUser = snapshot.data ?? user;

        return Scaffold(
          appBar: AppBar(title: const Text('Профиль')),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildProfileCard(context, currentUser),
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Настройки',
                [
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Уведомления',
                    subtitle: currentUser.notificationsEnabled
                        ? 'Включены'
                        : 'Выключены',
                    onTap: () async {
                      final updated = await Navigator.of(context).push<AppUser>(
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: currentUser),
                        ),
                      );
                      if (updated != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Настройки профиля обновлены'),
                          ),
                        );
                      }
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.currency_exchange,
                    title: 'Валюта',
                    subtitle: currentUser.currency ?? 'USD',
                    onTap: () async {
                      await Navigator.of(context).push<AppUser>(
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: currentUser),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Приложение',
                [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'О приложении',
                    subtitle: 'SubTrack v1.0.0',
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppTheme.surfaceCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('О приложении'),
                          content: const Text(
                            'SubTrack помогает вести все подписки в одном месте, следить за предстоящими списаниями и находить лишние расходы.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Понятно'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.star_outline,
                    title: 'Оценить приложение',
                    subtitle: 'Оставить отзыв',
                    onTap: () async {
                      await Clipboard.setData(
                        const ClipboardData(
                          text: 'Мне понравилось приложение SubTrack.',
                        ),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Текст отзыва скопирован в буфер обмена'),
                          ),
                        );
                      }
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.share_outlined,
                    title: 'Поделиться',
                    subtitle: 'Скопировать текст приглашения',
                    onTap: () async {
                      await Clipboard.setData(
                        const ClipboardData(
                          text:
                              'Попробуй SubTrack: приложение для контроля подписок и расходов.',
                        ),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Текст для отправки скопирован'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Аккаунт',
                [
                  _SettingsTile(
                    icon: Icons.edit_outlined,
                    title: 'Редактировать профиль',
                    subtitle: 'Имя, телефон, валюта',
                    onTap: () async {
                      await Navigator.of(context).push<AppUser>(
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(user: currentUser),
                        ),
                      );
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.logout,
                    title: 'Выйти',
                    textColor: AppTheme.danger,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: AppTheme.surfaceCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text('Выйти?'),
                          content: const Text('Вы уверены, что хотите выйти?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                'Отмена',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.danger,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Выйти'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'SubTrack — контролируй свои расходы',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, AppUser currentUser) {
    final initials = currentUser.firstName.isNotEmpty
        ? currentUser.firstName[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surfaceCard, AppTheme.surfaceElevated],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.accentGlow,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accent, width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser.displayName ?? currentUser.firstName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((currentUser.phoneNumber ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    currentUser.phoneNumber!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.textMuted),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: currentUser),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppTheme.textMuted,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => Column(
                    children: [
                      entry.value,
                      if (entry.key < items.length - 1)
                        const Divider(height: 1, indent: 52),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? textColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppTheme.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textMuted,
        size: 18,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
