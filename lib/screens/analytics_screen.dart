import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/subscription.dart';
import '../models/user_model.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  final AppUser user;
  const AnalyticsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final subService = SubscriptionService();

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: StreamBuilder<List<Subscription>>(
        stream: subService.subscriptionsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }

          final activeSubscriptions = (snapshot.data ?? [])
              .where((item) => item.status == SubscriptionStatus.active)
              .toList();

          final totalMonthly = activeSubscriptions.fold<double>(
            0,
            (sum, sub) => sum + sub.monthlyPrice,
          );
          final totalYearly = activeSubscriptions.fold<double>(
            0,
            (sum, sub) => sum + sub.yearlyPrice,
          );
          final byCategory = <String, double>{};
          final unused = <Subscription>[];
          for (final sub in activeSubscriptions) {
            byCategory[sub.category] =
                (byCategory[sub.category] ?? 0) + sub.monthlyPrice;
            if (sub.isUnused) {
              unused.add(sub);
            }
          }
          final totalCount = activeSubscriptions.length;
          final potentialSavings = unused.fold<double>(
            0,
            (sum, sub) => sum + sub.monthlyPrice,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _buildSummaryCards(
                  context, totalMonthly, totalYearly, totalCount),
              const SizedBox(height: 24),
              if (byCategory.isNotEmpty) ...[
                _buildCategoryChart(context, byCategory, totalMonthly),
                const SizedBox(height: 24),
              ],
              if (unused.isNotEmpty) ...[
                _buildSavingsCard(context, unused, potentialSavings),
                const SizedBox(height: 24),
              ],
              _buildCategoryBreakdown(context, byCategory),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(
      BuildContext context, double monthly, double yearly, int count) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'В месяц',
            value: '\$${monthly.toStringAsFixed(2)}',
            icon: '📅',
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'В год',
            value: '\$${yearly.toStringAsFixed(0)}',
            icon: '📆',
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Всего',
            value: '$count',
            icon: '📋',
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(
      BuildContext context, Map<String, double> byCategory, double total) {
    final sections = byCategory.entries.map((entry) {
      final color = AppTheme.categoryColors[entry.key] ?? AppTheme.textMuted;
      final percentage = total > 0 ? (entry.value / total * 100) : 0;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'По категориям',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 50,
                sectionsSpace: 3,
                pieTouchData: PieTouchData(enabled: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: byCategory.entries.map((entry) {
              final color =
                  AppTheme.categoryColors[entry.key] ?? AppTheme.textMuted;
              final emoji = AppTheme.categoryIcons[entry.key] ?? '📦';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$emoji ${entry.key}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(
      BuildContext context, List<Subscription> unused, double savings) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💰', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Потенциальная экономия',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$${savings.toStringAsFixed(2)}/мес',
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...unused.map((sub) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Text(
                      AppTheme.categoryIcons[sub.category] ?? '📦',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.name,
                        style: const TextStyle(
                          color: AppTheme.warning,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '\$${sub.monthlyPrice.toStringAsFixed(2)}/мес',
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      BuildContext context, Map<String, double> byCategory) {
    if (byCategory.isEmpty) return const SizedBox.shrink();

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sorted.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Расходы', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...sorted.map((entry) {
            final color =
                AppTheme.categoryColors[entry.key] ?? AppTheme.textMuted;
            final emoji = AppTheme.categoryIcons[entry.key] ?? '📦';
            final ratio = maxValue > 0 ? entry.value / maxValue : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.toDouble(),
                      backgroundColor: AppTheme.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
