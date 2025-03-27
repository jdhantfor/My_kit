import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Типы уведомлений
  static const String _expirationType = 'expiration';
  static const String _medicationType = 'medication';
  static const String _vaccinationType = 'vaccination';
  static const String _measurementType = 'measurement';
  static const String _thirdPartyType = 'third_party';

  // Генерация уникального ID для каждого уведомления с учётом типа
  static int _generateUniqueId(int reminderId, DateTime date, String type) {
    // Используем тип уведомления в ID, чтобы можно было различать
    final typeHash = type.hashCode % 1000; // Ограничиваем хэш типа
    return (typeHash * 1000000) +
        (reminderId * 1000) +
        (date.millisecondsSinceEpoch % 1000);
  }

  // Инициализация сервиса уведомлений с запросом разрешений на старте
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    final bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      print('Permissions not granted during initialization');
      _showPermissionDialog();
      return;
    }

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped with payload: ${response.payload}');
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushNamed('/today');
        } else {
          print('Navigator key is not set');
        }
      },
    );
    print('Notification service initialized successfully');
  }

  // Запрос всех необходимых разрешений
  static Future<bool> _requestPermissions() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    if (androidInfo.version.sdkInt >= 33) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        print('Notification permission denied');
        return false;
      }
    }

    if (androidInfo.version.sdkInt >= 31) {
      final status = await Permission.scheduleExactAlarm.request();
      if (!status.isGranted) {
        print('Exact alarm permission denied');
        return false;
      }
    }

    return true;
  }

  static void _showPermissionDialog() {
    if (navigatorKey.currentState != null) {
      showDialog(
        context: navigatorKey.currentState!.context,
        builder: (context) => AlertDialog(
          title: const Text('Разрешения на уведомления'),
          content: const Text(
              'Для работы напоминаний необходимо разрешить уведомления и точные будильники. Перейдите в настройки, чтобы включить их.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('Настройки'),
            ),
          ],
        ),
      );
    }
  }

  // Планирование уведомлений с учётом типа
  static Future<void> scheduleNotifications({
    required int reminderId,
    required String name,
    required DateTime startDate,
    required Map<String, dynamic> schedule,
    required String type,
  }) async {
    final List<DateTime> dates = _generateScheduleDates(startDate, schedule);

    for (final DateTime date in dates) {
      await scheduleNotification(
        id: _generateUniqueId(reminderId, date, type),
        title: 'Напоминание',
        body: 'Пришло время принять $name!',
        scheduledDate: date,
        type: type,
      );
    }
  }

  // Планирование одного уведомления
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String type,
  }) async {
    if (!await _requestPermissions()) {
      if (navigatorKey.currentState != null) {
        ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
          const SnackBar(content: Text('Разрешения не предоставлены')),
        );
      }
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'reminder_channel_id',
      'Reminders',
      channelDescription: 'Channel for medicine reminders',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      if (navigatorKey.currentState != null) {
        ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
          SnackBar(
              content: Text(
                  'Уведомление запланировано: ID=$id, Время=${scheduledDate.toString()}')),
        );
      }
    } catch (e) {
      if (navigatorKey.currentState != null) {
        ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
          SnackBar(content: Text('Ошибка планирования: $e')),
        );
      }
    }
  }

  // Отмена уведомлений по типу
  static Future<void> cancelNotificationsByType(String type) async {
    final pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();
    for (final notification in pendingNotifications) {
      final typeHash = type.hashCode % 1000;
      final notificationTypeHash = notification.id ~/ 1000000;
      if (notificationTypeHash == typeHash) {
        await _notificationsPlugin.cancel(notification.id);
        print('Cancelled notification: ID=${notification.id}, Type=$type');
      }
    }
  }

  // Генерация дат по расписанию (без изменений)
  static List<DateTime> _generateScheduleDates(
      DateTime start, Map<String, dynamic> schedule) {
    final String scheduleType = schedule['scheduleType'];
    final List<DateTime> dates = [];

    switch (scheduleType) {
      case 'daily':
        final DateTime end =
            schedule['endDate'] ?? start.add(const Duration(days: 365));
        for (var date = start;
            date.isBefore(end);
            date = date.add(const Duration(days: 1))) {
          dates.add(date);
        }
        break;

      case 'interval':
        final Duration interval = Duration(
          days: schedule['intervalUnit'] == 'дней'
              ? schedule['intervalValue']
              : 0,
        );
        final DateTime end =
            schedule['endDate'] ?? start.add(const Duration(days: 365));
        for (var date = start; date.isBefore(end); date = date.add(interval)) {
          dates.add(date);
        }
        break;

      case 'weekly':
        final List<String> days =
            List<String>.from(jsonDecode(schedule['selectedDays']));
        final DateTime end =
            schedule['endDate'] ?? start.add(const Duration(days: 365));
        for (var date = start;
            date.isBefore(end);
            date = date.add(const Duration(days: 1))) {
          if (days.contains(_getWeekdayName(date))) {
            dates.add(date);
          }
        }
        break;

      case 'cyclic':
        final int cycleDuration = schedule['cycleDuration'];
        final int cycleBreak = schedule['cycleBreak'];
        final DateTime end =
            schedule['endDate'] ?? start.add(const Duration(days: 365));
        var currentDate = start;
        var isActiveCycle = true;

        while (currentDate.isBefore(end)) {
          if (isActiveCycle) {
            dates.add(currentDate);
            currentDate = currentDate.add(const Duration(days: 1));
            if (currentDate.difference(start).inDays % cycleDuration == 0) {
              isActiveCycle = false;
            }
          } else {
            currentDate = currentDate.add(Duration(days: cycleBreak));
            isActiveCycle = true;
          }
        }
        break;

      case 'single':
        dates.add(start);
        break;
    }

    return dates;
  }

  static String _getWeekdayName(DateTime date) {
    return const ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'][date.weekday - 1];
  }

  // Отмена уведомления
  static Future<void> cancelNotification(int notificationId) async {
    await _notificationsPlugin.cancel(notificationId);
    print('Notification cancelled: ID=$notificationId');
  }

  // Отмена всех уведомлений
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    print('All notifications cancelled');
  }

  // Геттеры для типов уведомлений
  static String get expirationType => _expirationType;
  static String get medicationType => _medicationType;
  static String get vaccinationType => _vaccinationType;
  static String get measurementType => _measurementType;
  static String get thirdPartyType => _thirdPartyType;
}
