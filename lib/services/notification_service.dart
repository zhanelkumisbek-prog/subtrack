import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/subscription.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Schedule billing reminder (3 days before)
  Future<void> scheduleBillingReminder(Subscription sub) async {
    final reminderDate = sub.nextBillingDate.subtract(const Duration(days: 3));
    if (reminderDate.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      sub.id.hashCode,
      '💳 Скоро списание — ${sub.name}',
      'Через 3 дня спишется \$${sub.price.toStringAsFixed(2)}. Хотите отменить?',
      tz.TZDateTime.from(reminderDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'billing_reminders',
          'Напоминания об оплате',
          channelDescription: 'Уведомления о предстоящих списаниях',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFBEF264),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Notify about unused subscription
  Future<void> notifyUnused(Subscription sub) async {
    await _notifications.show(
      sub.id.hashCode + 10000,
      '😴 Вы не используете ${sub.name}',
      'Вы не заходили уже ${sub.lastUsedDaysAgo} дней. Может, отменить подписку?',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'unused_alerts',
          'Неиспользуемые подписки',
          channelDescription: 'Уведомления о неиспользуемых подписках',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
    );
  }

  Future<void> cancelSubscriptionNotification(String subId) async {
    await _notifications.cancel(subId.hashCode);
    await _notifications.cancel(subId.hashCode + 10000);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> showPasswordResetCode(String phoneNumber, String code) async {
    await _notifications.show(
      phoneNumber.hashCode + 30000,
      'Код восстановления пароля',
      'Код для номера $phoneNumber: $code',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'password_reset',
          'Восстановление пароля',
          channelDescription: 'Коды восстановления пароля',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
