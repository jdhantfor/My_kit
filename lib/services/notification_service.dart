import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import 'dart:io' show Platform;

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
 static int _generateUniqueId(int reminderId, DateTime date, String type, int dateIndex, int timeIndex) {
  // Ограничиваем значения, чтобы итоговый ID был в пределах 32-битного диапазона
  final typeHash = type.hashCode % 10; // 0-9
  final reminderPart = reminderId % 1000; // 0-999
  final datePart = dateIndex % 100; // 0-99
  final timePart = timeIndex % 100; // 0-99
  final dateHash = (date.millisecondsSinceEpoch % 1000) ~/ 100; // 0-9

  // Формула: typeHash * 10000000 + reminderPart * 10000 + datePart * 100 + timePart * 1 + dateHash
  // Максимум: 9 * 10000000 + 999 * 10000 + 99 * 100 + 99 * 1 + 9 = 99,999,999
  // Но это всё ещё слишком много, так как 2^31 - 1 = 2,147,483,647
  // Уменьшим множители: typeHash * 100000 + reminderPart * 1000 + datePart * 10 + timePart * 1 + dateHash
  // Максимум: 9 * 100000 + 999 * 1000 + 99 * 10 + 99 * 1 + 9 = 1,900,998 (в пределах 2^31)
  return (typeHash * 100000) + (reminderPart * 1000) + (datePart * 10) + (timePart * 1) + dateHash;
}
  // Инициализация сервиса уведомлений с запросом разрешений на старте
  static Future<void> initialize() async {
  tz.initializeTimeZones();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

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

  if (Platform.isAndroid) {
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
  }

  if (Platform.isIOS) {
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final bool? granted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (granted != true) {
      print('iOS notification permissions denied');
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
  print('Scheduling notifications: reminderId=$reminderId, type=$type, startDate=$startDate, schedule=$schedule');
  final List<DateTime> dates = _generateScheduleDates(startDate, schedule);
  print('Generated dates: $dates');

  final List<Map<String, dynamic>> timesAndDosages =
      List<Map<String, dynamic>>.from(schedule['timesAndDosages'] ?? []);

  if (timesAndDosages.isEmpty) {
    print('No times and dosages provided for reminderId: $reminderId');
    return;
  }

  final now = DateTime.now();
  final maxScheduleDate = now.add(Duration(days: 30));

  int notificationCount = 0;
  for (int dateIndex = 0; dateIndex < dates.length; dateIndex++) {
    final DateTime date = dates[dateIndex];
    if (date.isAfter(maxScheduleDate)) {
      print('Reached max scheduling date ($maxScheduleDate), stopping.');
      break;
    }

    for (int timeIndex = 0; timeIndex < timesAndDosages.length; timeIndex++) {
      final timeAndDosage = timesAndDosages[timeIndex];
      final time = timeAndDosage['time'] as String;
      final dosage = timeAndDosage['dosage'] as int;
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final scheduledDate = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      if (scheduledDate.isAfter(now)) {
        await scheduleNotification(
          id: _generateUniqueId(reminderId, scheduledDate, type, dateIndex, timeIndex),
          title: 'Напоминание',
          body: 'Пришло время принять $name! Дозировка: $dosage мг',
          scheduledDate: scheduledDate,
          type: type,
        );
        notificationCount++;
      }
    }
  }

  print('Scheduled $notificationCount notifications for reminderId: $reminderId');
}


  // Генерация дат по расписанию
static List<DateTime> _generateScheduleDates(
    DateTime start, Map<String, dynamic> schedule) {
  print('Generating schedule dates with start=$start, schedule=$schedule');
  final String scheduleType = schedule['scheduleType'];
  final List<DateTime> dates = [];

  switch (scheduleType) {
    case 'daily':
      final DateTime end =
          schedule['endDate'] ?? start.add(const Duration(days: 365));
      for (var date = start;
          date.isBefore(end) || date.isAtSameMomentAs(end);
          date = date.add(const Duration(days: 1))) {
        dates.add(date);
      }
      break;

    case 'interval':
      final Duration interval = Duration(
        days: schedule['intervalUnit'] == 'дней' ? schedule['intervalValue'] : 0,
      );
      final DateTime end =
          schedule['endDate'] ?? start.add(const Duration(days: 365));
      for (var date = start;
          date.isBefore(end) || date.isAtSameMomentAs(end);
          date = date.add(interval)) {
        dates.add(date);
      }
      break;

    case 'weekly':
      final List<String> days =
          List<String>.from(jsonDecode(schedule['selectedDays']));
      final DateTime end =
          schedule['endDate'] ?? start.add(const Duration(days: 365));
      for (var date = start;
          date.isBefore(end) || date.isAtSameMomentAs(end);
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

      while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
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

  print('Generated dates: $dates');
  return dates;
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

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'reminder_channel_id',
    'Reminders',
    channelDescription: 'Channel for medicine reminders',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'ticker',
    playSound: true,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  try {
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    print('Timezone used: ${tz.local.name}');
    print('Scheduled date in local timezone: $tzScheduledDate');
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    print('Уведомление запланировано: ID=$id, Время=$tzScheduledDate');
  } catch (e) {
    print('Ошибка планирования уведомления: $e');
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
