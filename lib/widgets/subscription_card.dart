import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../models/user_model.dart';
import '../services/subscription_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../screens/add_subscription_screen.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final AppUser user;
  final bool compact;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.user,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final color = AppTheme.categoryColors[sub.category] ?? AppTheme.textMuted;
    final emoji = AppTheme.categoryIcons[sub.category] ?? '📦';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: sub.isUnused
              ? AppTheme.warning.withValues(alpha: 0.4)
              : AppTheme.border,
          width: sub.isUnused ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildIcon(emoji, color),
                const SizedBox(width: 14),
                Expanded(child: _buildInfo(context, sub)),
                _buildPrice(context, sub),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String emoji, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, Subscription sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                sub.name,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sub.isUnused) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warningDim,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'не используется',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (sub.isDueSoon)
              Text(
                'Через ${sub.daysUntilBilling} дн.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text(
                DateFormat('d MMM', 'ru').format(sub.nextBillingDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                    ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrice(BuildContext context, Subscription sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${sub.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          sub.billingCycleLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _SubscriptionDetailSheet(
        subscription: subscription,
        user: user,
      ),
    );
  }
}

class _SubscriptionDetailSheet extends StatelessWidget {
  final Subscription subscription;
  final AppUser user;

  const _SubscriptionDetailSheet({
    required this.subscription,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subscription;
    final color = AppTheme.categoryColors[sub.category] ?? AppTheme.textMuted;
    final emoji = AppTheme.categoryIcons[sub.category] ?? '📦';
    final _subService = SubscriptionService();
    final notificationService = NotificationService();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Text(
                          sub.category,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Price info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    _InfoItem(
                      label: 'В месяц',
                      value: '\$${sub.monthlyPrice.toStringAsFixed(2)}',
                    ),
                    Container(
                        height: 40,
                        width: 1,
                        color: AppTheme.border,
                        margin: const EdgeInsets.symmetric(horizontal: 16)),
                    _InfoItem(
                      label: 'В год',
                      value: '\$${sub.yearlyPrice.toStringAsFixed(2)}',
                    ),
                    Container(
                        height: 40,
                        width: 1,
                        color: AppTheme.border,
                        margin: const EdgeInsets.symmetric(horizontal: 16)),
                    _InfoItem(
                      label: 'Оплата',
                      value: sub.billingCycleLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Next billing
              _DetailRow(
                icon: Icons.calendar_month_outlined,
                label: 'Следующее списание',
                value:
                    DateFormat('d MMMM yyyy', 'ru').format(sub.nextBillingDate),
                valueColor: sub.isDueSoon ? AppTheme.danger : null,
              ),

              if (sub.isUnused) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.warningDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Text('😴', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Вы не пользуетесь ${sub.name} уже ${sub.lastUsedDaysAgo} дней. Рассмотрите отмену.',
                          style: const TextStyle(
                            color: AppTheme.warning,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _subService.markAsUsed(user.uid, sub.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Я использовал сегодня'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddSubscriptionScreen(
                          user: user,
                          existing: sub,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Редактировать'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => _CancelDialog(name: sub.name),
                    );
                    if (confirm == true) {
                      await _subService.cancelSubscription(user.uid, sub.id);
                      await notificationService.cancelSubscriptionNotification(
                        sub.id,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon:
                      const Icon(Icons.cancel_outlined, color: AppTheme.danger),
                  label: const Text('Отменить подписку'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => _DeleteDialog(name: sub.name),
                    );
                    if (confirm == true) {
                      await _subService.deleteSubscription(user.uid, sub.id);
                      await notificationService.cancelSubscriptionNotification(
                        sub.id,
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon:
                      const Icon(Icons.delete_outline, color: AppTheme.danger),
                  label: const Text('Удалить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelDialog extends StatelessWidget {
  final String name;
  const _CancelDialog({required this.name});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Отменить $name?',
          style: Theme.of(context).textTheme.titleLarge),
      content: Text(
        'Вы уверены, что хотите отметить эту подписку как отменённую?',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Нет',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
          ),
          child: const Text('Отменить'),
        ),
      ],
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  final String name;
  const _DeleteDialog({required this.name});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Удалить $name?',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: Text(
        'Подписка будет удалена полностью. Это действие нельзя отменить.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Нет',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
          ),
          child: const Text('Удалить'),
        ),
      ],
    );
  }
}
