import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_todo/services/notification_service.dart';

void main() {
  group('NotificationService Tests (FakeNotificationService)', () {
    late FakeNotificationService notificationService;

    setUp(() {
      notificationService = FakeNotificationService();
    });

    test('1. should schedule notification when scheduledDate is in the future', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));

      await notificationService.scheduleNotification(
        id: 101,
        title: 'Lembrete',
        body: 'Estudar Flutter',
        scheduledDate: futureDate,
      );

      expect(notificationService.scheduledNotifications.containsKey(101), true);
      final notification = notificationService.scheduledNotifications[101];
      expect(notification?.title, 'Lembrete');
      expect(notification?.body, 'Estudar Flutter');
      expect(notification?.scheduledDate, futureDate);
    });

    test('2. should not schedule notification when scheduledDate is in the past', () async {
      final pastDate = DateTime.now().subtract(const Duration(hours: 1));

      await notificationService.scheduleNotification(
        id: 102,
        title: 'Lembrete Antigo',
        body: 'Tarefa Passada',
        scheduledDate: pastDate,
      );

      expect(notificationService.scheduledNotifications.containsKey(102), false);
    });

    test('3. should cancel scheduled notification by id', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));

      await notificationService.scheduleNotification(
        id: 103,
        title: 'Lembrete a Cancelar',
        body: 'Cancelar esta notificação',
        scheduledDate: futureDate,
      );

      expect(notificationService.scheduledNotifications.containsKey(103), true);

      await notificationService.cancelNotification(103);

      expect(notificationService.scheduledNotifications.containsKey(103), false);
    });

    test('4. should not schedule notification if permission is denied', () async {
      notificationService.permissionGranted = false;
      final futureDate = DateTime.now().add(const Duration(hours: 2));

      await notificationService.scheduleNotification(
        id: 104,
        title: 'Sem Permissão',
        body: 'Não deve ser agendado',
        scheduledDate: futureDate,
      );

      expect(notificationService.scheduledNotifications.containsKey(104), false);
    });

    test('5. should cancel all notifications', () async {
      final futureDate = DateTime.now().add(const Duration(hours: 2));

      await notificationService.scheduleNotification(id: 1, title: 'T1', body: 'B1', scheduledDate: futureDate);
      await notificationService.scheduleNotification(id: 2, title: 'T2', body: 'B2', scheduledDate: futureDate);

      expect(notificationService.scheduledNotifications.length, 2);

      await notificationService.cancelAllNotifications();

      expect(notificationService.scheduledNotifications.isEmpty, true);
    });
  });
}
