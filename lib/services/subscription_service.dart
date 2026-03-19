import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/subscription.dart';

class SubscriptionService {
  static final StreamController<_SubscriptionEvent> _controller =
      StreamController<_SubscriptionEvent>.broadcast();
  static const _storagePrefix = 'subscriptions_';

  Stream<List<Subscription>> subscriptionsStream(String uid) async* {
    yield await _loadSubscriptions(uid);
    yield* _controller.stream.where((event) => event.uid == uid).map(
          (event) => event.subscriptions,
        );
  }

  Future<void> addSubscription(String uid, Subscription sub) async {
    final subs = await _loadSubscriptions(uid);
    subs.removeWhere((item) => item.id == sub.id);
    subs.add(sub);
    await _saveSubscriptions(uid, subs);
  }

  Future<void> updateSubscription(String uid, Subscription sub) async {
    final subs = await _loadSubscriptions(uid);
    final index = subs.indexWhere((item) => item.id == sub.id);
    if (index == -1) {
      subs.add(sub);
    } else {
      subs[index] = sub;
    }
    await _saveSubscriptions(uid, subs);
  }

  Future<void> deleteSubscription(String uid, String subId) async {
    final subs = await _loadSubscriptions(uid);
    subs.removeWhere((item) => item.id == subId);
    await _saveSubscriptions(uid, subs);
  }

  Future<void> cancelSubscription(String uid, String subId) async {
    final subs = await _loadSubscriptions(uid);
    final index = subs.indexWhere((item) => item.id == subId);
    if (index == -1) return;

    subs[index] = subs[index].copyWith(status: SubscriptionStatus.cancelled);
    await _saveSubscriptions(uid, subs);
  }

  Future<void> markAsUsed(String uid, String subId) async {
    final subs = await _loadSubscriptions(uid);
    final index = subs.indexWhere((item) => item.id == subId);
    if (index == -1) return;

    subs[index] = subs[index].copyWith(lastUsedDaysAgo: 0);
    await _saveSubscriptions(uid, subs);
  }

  Future<void> toggleNotifications(
      String uid, String subId, bool enabled) async {
    final subs = await _loadSubscriptions(uid);
    final index = subs.indexWhere((item) => item.id == subId);
    if (index == -1) return;

    subs[index] = subs[index].copyWith(notificationsEnabled: enabled);
    await _saveSubscriptions(uid, subs);
  }

  Future<Map<String, dynamic>> getAnalytics(String uid) async {
    final allSubs = await _loadSubscriptions(uid);
    final subs = allSubs
        .where((item) => item.status == SubscriptionStatus.active)
        .toList();

    double totalMonthly = 0;
    double totalYearly = 0;
    Map<String, double> byCategory = {};
    List<Subscription> unused = [];
    List<Subscription> dueSoon = [];

    for (final sub in subs) {
      totalMonthly += sub.monthlyPrice;
      totalYearly += sub.yearlyPrice;

      byCategory[sub.category] =
          (byCategory[sub.category] ?? 0) + sub.monthlyPrice;

      if (sub.isUnused) unused.add(sub);
      if (sub.isDueSoon) dueSoon.add(sub);
    }

    return {
      'totalMonthly': totalMonthly,
      'totalYearly': totalYearly,
      'totalCount': subs.length,
      'byCategory': byCategory,
      'unused': unused,
      'dueSoon': dueSoon,
      'potentialSavings': unused.fold<double>(
          0, (sum, sub) => sum + sub.monthlyPrice),
    };
  }

  Future<List<Subscription>> _loadSubscriptions(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_storagePrefix$uid');
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final subscriptions = decoded
        .map((item) => Subscription.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    subscriptions.sort(
      (a, b) => a.nextBillingDate.compareTo(b.nextBillingDate),
    );
    return subscriptions;
  }

  Future<void> _saveSubscriptions(String uid, List<Subscription> subs) async {
    final prefs = await SharedPreferences.getInstance();
    subs.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    await prefs.setString(
      '$_storagePrefix$uid',
      jsonEncode(subs.map((item) => item.toMap()).toList()),
    );
    _controller.add(_SubscriptionEvent(uid, List<Subscription>.from(subs)));
  }
}

class _SubscriptionEvent {
  final String uid;
  final List<Subscription> subscriptions;

  const _SubscriptionEvent(this.uid, this.subscriptions);
}
