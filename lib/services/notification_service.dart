import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(settings);
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      bool? androidGranted;
      if (androidImplementation != null) {
        androidGranted = await androidImplementation.requestNotificationsPermission();
      }

      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      bool? iosGranted;
      if (iosImplementation != null) {
        iosGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      return androidGranted ?? iosGranted ?? true;
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    try {
      await requestPermissions();

      final scheduledTzDate = tz.TZDateTime.from(scheduledDate, tz.local);

      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders_channel',
          'Lembretes de Tarefas',
          channelDescription: 'Notificações para tarefas com prazo de vencimento',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTzDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }
}

class FakeNotificationService implements NotificationService {
  bool permissionGranted = true;
  final Map<int, ScheduledNotification> scheduledNotifications = {};
  bool isInitialized = false;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    return permissionGranted;
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }
    if (!permissionGranted) {
      return;
    }
    scheduledNotifications[id] = ScheduledNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    scheduledNotifications.remove(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    scheduledNotifications.clear();
  }
}

class ScheduledNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;

  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
  });
}
