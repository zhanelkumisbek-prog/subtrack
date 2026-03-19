import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../models/user_model.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/subscription_card.dart';
import 'add_subscription_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  final AppUser user;
  const SubscriptionsScreen({super.key, required this.user});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  final _subService = SubscriptionService();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подписки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddSubscriptionScreen(user: widget.user),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'Активные'),
            Tab(text: 'Отменённые'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(SubscriptionStatus.active),
                _buildList(SubscriptionStatus.cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Поиск подписок...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: AppTheme.surfaceElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildList(SubscriptionStatus status) {
    return StreamBuilder<List<Subscription>>(
      stream: _subService.subscriptionsStream(widget.user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }

        var subs = (snapshot.data ?? [])
            .where((s) => s.status == status)
            .toList();

        if (_searchQuery.isNotEmpty) {
          subs = subs
              .where((s) => s.name.toLowerCase().contains(_searchQuery))
              .toList();
        }

        if (subs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status == SubscriptionStatus.active ? '📋' : '✅',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  status == SubscriptionStatus.active
                      ? 'Нет активных подписок'
                      : 'Нет отменённых подписок',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          );
        }

        // Group by category
        final grouped = <String, List<Subscription>>{};
        for (final sub in subs) {
          grouped.putIfAbsent(sub.category, () => []).add(sub);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: grouped.keys.length,
          itemBuilder: (_, i) {
            final category = grouped.keys.elementAt(i);
            final categorySubs = grouped[category]!;
            final emoji =
                AppTheme.categoryIcons[category] ?? '📦';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(emoji),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${categorySubs.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...categorySubs.map((sub) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SubscriptionCard(
                        subscription: sub,
                        user: widget.user,
                      ),
                    )),
              ],
            );
          },
        );
      },
    );
  }
}
