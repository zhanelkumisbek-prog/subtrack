import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/subscription_card.dart';
import 'add_subscription_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _subService = SubscriptionService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Subscription>>(
          stream: _subService.subscriptionsStream(widget.user.uid),
          builder: (context, snapshot) {
            final subs = snapshot.data ?? [];
            final activeSubs =
                subs.where((s) => s.status == SubscriptionStatus.active).toList();
            final totalMonthly = activeSubs.fold<double>(
                0, (sum, s) => sum + s.monthlyPrice);
            final unusedSubs = activeSubs.where((s) => s.isUnused).toList();
            final dueSoonSubs = activeSubs.where((s) => s.isDueSoon).toList();

            return CustomScrollView(
              slivers: [
                _buildHeader(totalMonthly, activeSubs.length),
                if (unusedSubs.isNotEmpty)
                  _buildUnusedAlert(unusedSubs),
                if (dueSoonSubs.isNotEmpty)
                  _buildDueSoonSection(dueSoonSubs),
                _buildRecentSection(activeSubs),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddSubscriptionScreen(user: widget.user),
          ),
        ),
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.background,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(double totalMonthly, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Привет, ${widget.user.firstName} 👋',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SubTrack',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontFamily: 'Syne',
                            color: AppTheme.accent,
                          ),
                    ),
                  ],
                ),
                _buildAvatar(),
              ],
            ),
            const SizedBox(height: 28),
            _buildSpendCard(totalMonthly, count),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initials = widget.user.firstName.isNotEmpty
        ? widget.user.firstName[0].toUpperCase()
        : '?';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.accentGlow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }

  Widget _buildSpendCard(double totalMonthly, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2A0A), Color(0xFF0D1A05)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentDim, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Расходы в месяц',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.accent.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${totalMonthly.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: AppTheme.accent,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.receipt_outlined,
                label: '$count подписок',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.calendar_month_outlined,
                label: '\$${(totalMonthly * 12).toStringAsFixed(0)} в год',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentGlow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnusedAlert(List<Subscription> unused) {
    final savings = unused.fold<double>(0, (s, sub) => s + sub.monthlyPrice);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.warningDim,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${unused.length} неиспользуемых подписок',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Сэкономьте \$${savings.toStringAsFixed(2)}/мес, отменив их',
                      style: TextStyle(
                        color: AppTheme.warning.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueSoonSection(List<Subscription> dueSoon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Скоро оплата',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...dueSoon.map((sub) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                    child: SubscriptionCard(
                      subscription: sub,
                      user: widget.user,
                      compact: true,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSection(List<Subscription> subs) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Все активные',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (subs.isEmpty)
              _buildEmptyState()
            else
              ...subs.map((sub) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SubscriptionCard(
                      subscription: sub,
                      user: widget.user,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Text('📋', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 16),
          Text(
            'Нет подписок',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите + чтобы добавить первую подписку',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
