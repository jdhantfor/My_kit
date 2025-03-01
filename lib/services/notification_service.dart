import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart'; // Для запроса разрешений
import 'package:device_info_plus/device_info_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Генерация уникального ID для каждого уведомления
  static int _generateUniqueId(int reminderId, DateTime date) {
    return reminderId + date.millisecondsSinceEpoch;
  }

  // Генерация дат по расписанию
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
        final Map<String, int> dayMap = {
          'Пн': 1,
          'Вт': 2,
          'Ср': 3,
          'Чт': 4,
          'Пт': 5,
          'Сб': 6,
          'Вс': 7,
        };
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

  // Вспомогательный метод для получения дня недели
  static String _getWeekdayName(DateTime date) {
    return const ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'][date.weekday - 1];
  }

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // Инициализация сервиса уведомлений
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (payload) {
        print('Notification tapped with payload: ${payload.payload}');
        navigatorKey.currentState?.pushNamed('/today');
      },
    );

    // Инициализация временных зон
    tz.initializeTimeZones();
  }

  // Планирование уведомлений
  static Future<void> scheduleNotifications({
    required int reminderId,
    required String name,
    required DateTime startDate,
    required Map<String, dynamic> schedule,
  }) async {
    final List<DateTime> dates = _generateScheduleDates(startDate, schedule);

    for (final DateTime date in dates) {
      await scheduleNotification(
        id: _generateUniqueId(reminderId, date),
        title: 'Напоминание',
        body: 'Пришло время принять $name!',
        scheduledDate: date,
      );
    }
  }

  // Планирование одного уведомления
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (await requestExactAlarmPermission(navigatorKey.currentContext!)) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'your_channel_id',
        'Your Channel Name',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  // Запрос разрешения на точные уведомления
  static Future<bool> requestExactAlarmPermission(BuildContext context) async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    // Проверяем версию Android
    if (androidInfo.version.sdkInt >= 31) {
      final PermissionStatus status =
          await Permission.scheduleExactAlarm.request();

      if (status.isGranted) {
        return true; // Разрешение предоставлено
      } else {
        // Если разрешение не предоставлено, показываем диалог
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Точные уведомления'),
            content: const Text(
                'Для работы напоминаний требуется разрешение на точные уведомления. '
                'Пожалуйста, предоставьте его в настройках устройства.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await openAppSettings(); // Открываем настройки приложения
                },
                child: const Text('Настройки'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ],
          ),
        );

        return false; // Разрешение не предоставлено
      }
    }

    // Для устройств с Android ниже 12 разрешение не требуется
    return true;
  }

  // Отмена уведомления
  static Future<void> cancelNotification(int notificationId) async {
    await _notificationsPlugin.cancel(notificationId);
  }

  // Отмена всех уведомлений
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
