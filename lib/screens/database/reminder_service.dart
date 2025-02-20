import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/services/notification_service.dart';
import 'package:my_aptechka/screens/models/reminder_status.dart';

class ReminderService {
  final Database db;

  ReminderService(this.db);

  // Метод для конвертации дней недели в битовую маску
  static int daysToMask(List<String> days) {
    const dayMap = {
      'Пн': 1,
      'Вт': 2,
      'Ср': 4,
      'Чт': 8,
      'Пт': 16,
      'Сб': 32,
      'Вс': 64
    };
    return days.fold(0, (mask, day) => mask | (dayMap[day] ?? 0));
  }

  // Методы для работы с напоминаниями (reminders)
  Future<int> addReminder(Map<String, dynamic> reminder, String userId) async {
    final Map<String, dynamic> reminderToInsert = {
      'name': reminder['name'],
      'time': reminder['time'],
      'dosage': reminder['dosage'],
      'unit': reminder['unit'],
      'selectTime': reminder['selectTime'],
      'startDate': reminder['startDate'],
      'endDate': reminder['endDate'],
      'isLifelong': reminder['isLifelong'],
      'schedule_type': reminder['schedule_type'],
      'interval_value': reminder['interval_value'],
      'interval_unit': reminder['interval_unit'],
      'selected_days_mask': reminder['selected_days_mask'],
      'cycle_duration': reminder['cycle_duration'],
      'cycle_break': reminder['cycle_break'],
      'cycle_break_unit': reminder['cycle_break_unit'] ?? 'дней',
      'courseid': reminder['courseid'],
      'user_id': userId,
    };

    reminderToInsert
        .removeWhere((key, value) => key != 'courseid' && value == null);

    final insertedReminderId = await db.insert(
      'reminders_table',
      reminderToInsert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (reminder['selectTime'] != null && reminder['startDate'] != null) {
      final timeParts = reminder['selectTime'].toString().split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = int.tryParse(timeParts[1]) ?? 0;
      final scheduledDate = DateTime(
        DateTime.parse(reminder['startDate']).year,
        DateTime.parse(reminder['startDate']).month,
        DateTime.parse(reminder['startDate']).day,
        hour,
        minute,
      );

      if (scheduledDate.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(
          id: insertedReminderId,
          title: 'Напоминание',
          body: 'Пришло время принять ${reminder['name']}!',
          scheduledDate: scheduledDate,
        );
      }
    }

    return insertedReminderId;
  }

  Future<List<Map<String, dynamic>>> getReminders(String userId) async {
    return await db
        .query('reminders_table', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> updateReminder(
      Map<String, dynamic> reminder, String userId) async {
    await db.update(
      'reminders_table',
      {...reminder, 'user_id': userId},
      where: 'id = ? AND user_id = ?',
      whereArgs: [reminder['id'], userId],
    );
  }

  Future<void> deleteReminder(int id, String userId) async {
    await db.delete(
      'reminders_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<Map<String, dynamic>>> getRemindersByCourseId(
      int courseId, String userId) async {
    return await db.query(
      'reminders_table',
      where: 'courseid = ? AND user_id = ?',
      whereArgs: [courseId, userId],
    );
  }

  Future<ReminderStatus?> getReminderStatusForDate(
      int reminderId, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final result = await db.query(
      'reminder_statuses',
      where: 'reminder_id = ? AND date = ?',
      whereArgs: [reminderId, dateString],
      limit: 1,
    );
    if (result.isNotEmpty) {
      final statusValue = result.first['is_completed'];
      return statusValue == 1
          ? ReminderStatus.complete
          : ReminderStatus.incomplete;
    } else {
      return null;
    }
  }

  Future<void> updateReminderCompletionStatus(
      int reminderId, bool isCompleted, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);

    final reminder = await db.query(
      'reminders_table',
      columns: ['user_id'],
      where: 'id = ?',
      whereArgs: [reminderId],
      limit: 1,
    );
    if (reminder.isEmpty) {
      throw Exception('Reminder not found');
    }
    final userId = reminder.first['user_id'] as String;

    await db.transaction((txn) async {
      await txn.insert(
        'reminder_statuses',
        {
          'reminder_id': reminderId,
          'date': dateString,
          'is_completed': isCompleted ? 1 : 0,
          'user_id': userId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (isCompleted) {
        await NotificationService.cancelNotification(reminderId);
      }
    });
  }

  // Методы для работы с действиями (actions)
  Future<int> addActionOrHabit(
      Map<String, dynamic> action, String userId) async {
    action['user_id'] = userId;
    return await db.insert('actions_table', action);
  }

  Future<List<Map<String, dynamic>>> getActions(String userId) async {
    return await db
        .query('actions_table', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<void> updateAction(Map<String, dynamic> action, String userId) async {
    await db.update(
      'actions_table',
      {...action, 'user_id': userId},
      where: 'id = ? AND user_id = ?',
      whereArgs: [action['id'], userId],
    );
  }

  Future<void> updateActionStatus(int id, bool isCompleted) async {
    await db.update(
      'actions_table',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getActionsByDate(
      String userId, DateTime date) async {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return await db.rawQuery('''
      SELECT * FROM actions_table 
      WHERE user_id = ? AND startDate <= ? AND (endDate >= ? OR endDate IS NULL)
    ''', [userId, dateString, dateString]);
  }

  Future<List<Map<String, dynamic>>> getMeasurements(String userId) async {
    final List<Map<String, dynamic>> result = await db.query(
      'measurements_table',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    for (var measurement in result) {
      measurement['isLifelong'] =
          measurement['isLifelong'] == 1; // Преобразуем int в bool
      measurement['times'] =
          jsonDecode(measurement['times']); // Декодируем JSON обратно в список
    }

    return result;
  }

  Future<void> updateMeasurementStatus(int id, bool isCompleted) async {
    await db.update(
      'measurements_table',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateMeasurement(
      Map<String, dynamic> measurement, String userId) async {
    await db.update(
      'measurements_table',
      {
        ...measurement,
        'user_id': userId,
        'times': jsonEncode(
            measurement['times']), // Преобразуем список времен в JSON
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [measurement['id'], userId],
    );
  }

  Future<void> deleteMeasurement(int id, String userId) async {
    await db.delete(
      'measurements_table',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }
}
