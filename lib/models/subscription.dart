import 'package:flutter/material.dart';

enum BillingCycle { monthly, yearly, weekly }

enum SubscriptionStatus { active, cancelled, paused }

class Subscription {
  final String id;
  final String name;
  final String category;
  final double price;
  final BillingCycle billingCycle;
  final DateTime nextBillingDate;
  final DateTime startDate;
  final SubscriptionStatus status;
  final String? logoUrl;
  final String? notes;
  final bool notificationsEnabled;
  final int? lastUsedDaysAgo; // null = unknown, 0 = today

  const Subscription({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.billingCycle,
    required this.nextBillingDate,
    required this.startDate,
    this.status = SubscriptionStatus.active,
    this.logoUrl,
    this.notes,
    this.notificationsEnabled = true,
    this.lastUsedDaysAgo,
  });

  double get monthlyPrice {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return price * 4.33;
      case BillingCycle.monthly:
        return price;
      case BillingCycle.yearly:
        return price / 12;
    }
  }

  double get yearlyPrice {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return price * 52;
      case BillingCycle.monthly:
        return price * 12;
      case BillingCycle.yearly:
        return price;
    }
  }

  bool get isUnused =>
      lastUsedDaysAgo != null && lastUsedDaysAgo! > 14;

  bool get isDueSoon {
    final diff = nextBillingDate.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 7;
  }

  int get daysUntilBilling =>
      nextBillingDate.difference(DateTime.now()).inDays;

  String get billingCycleLabel {
    switch (billingCycle) {
      case BillingCycle.weekly:
        return 'в нед.';
      case BillingCycle.monthly:
        return 'в мес.';
      case BillingCycle.yearly:
        return 'в год';
    }
  }

  factory Subscription.fromMap(Map<String, dynamic> data) {
    return Subscription(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? 'other',
      price: (data['price'] ?? 0.0).toDouble(),
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == (data['billingCycle'] ?? 'monthly'),
        orElse: () => BillingCycle.monthly,
      ),
      nextBillingDate:
          DateTime.tryParse(data['nextBillingDate'] ?? '') ?? DateTime.now(),
      startDate:
          DateTime.tryParse(data['startDate'] ?? '') ?? DateTime.now(),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'active'),
        orElse: () => SubscriptionStatus.active,
      ),
      logoUrl: data['logoUrl'],
      notes: data['notes'],
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      lastUsedDaysAgo: data['lastUsedDaysAgo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'billingCycle': billingCycle.name,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'status': status.name,
      'logoUrl': logoUrl,
      'notes': notes,
      'notificationsEnabled': notificationsEnabled,
      'lastUsedDaysAgo': lastUsedDaysAgo,
    };
  }

  Subscription copyWith({
    String? name,
    String? category,
    double? price,
    BillingCycle? billingCycle,
    DateTime? nextBillingDate,
    DateTime? startDate,
    SubscriptionStatus? status,
    String? logoUrl,
    String? notes,
    bool? notificationsEnabled,
    int? lastUsedDaysAgo,
  }) {
    return Subscription(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      billingCycle: billingCycle ?? this.billingCycle,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      startDate: startDate ?? this.startDate,
      status: status ?? this.status,
      logoUrl: logoUrl ?? this.logoUrl,
      notes: notes ?? this.notes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastUsedDaysAgo: lastUsedDaysAgo ?? this.lastUsedDaysAgo,
    );
  }
}

// Pre-defined popular services
class PopularService {
  final String name;
  final String category;
  final String emoji;
  final double suggestedPrice;
  final Color color;

  const PopularService({
    required this.name,
    required this.category,
    required this.emoji,
    required this.suggestedPrice,
    required this.color,
  });
}

const List<PopularService> popularServices = [
  PopularService(name: 'Netflix', category: 'streaming', emoji: '🎬', suggestedPrice: 15.99, color: Color(0xFFE50914)),
  PopularService(name: 'Spotify', category: 'music', emoji: '🎵', suggestedPrice: 9.99, color: Color(0xFF1DB954)),
  PopularService(name: 'YouTube Premium', category: 'streaming', emoji: '▶️', suggestedPrice: 13.99, color: Color(0xFFFF0000)),
  PopularService(name: 'Apple Music', category: 'music', emoji: '🎼', suggestedPrice: 10.99, color: Color(0xFFFC3C44)),
  PopularService(name: 'Disney+', category: 'streaming', emoji: '✨', suggestedPrice: 7.99, color: Color(0xFF0063E5)),
  PopularService(name: 'HBO Max', category: 'streaming', emoji: '🎭', suggestedPrice: 15.99, color: Color(0xFF5200FF)),
  PopularService(name: 'Amazon Prime', category: 'streaming', emoji: '📦', suggestedPrice: 14.99, color: Color(0xFF00A8E0)),
  PopularService(name: 'Notion', category: 'productivity', emoji: '📝', suggestedPrice: 8.00, color: Color(0xFF000000)),
  PopularService(name: 'Adobe CC', category: 'productivity', emoji: '🎨', suggestedPrice: 54.99, color: Color(0xFFFF0000)),
  PopularService(name: 'ChatGPT Plus', category: 'productivity', emoji: '🤖', suggestedPrice: 20.00, color: Color(0xFF10A37F)),
  PopularService(name: 'iCloud+', category: 'cloud', emoji: '☁️', suggestedPrice: 2.99, color: Color(0xFF007AFF)),
  PopularService(name: 'Google One', category: 'cloud', emoji: '🔷', suggestedPrice: 2.99, color: Color(0xFF4285F4)),
];
