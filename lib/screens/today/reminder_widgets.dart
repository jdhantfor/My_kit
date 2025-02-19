// reminder_widgets.dart
import 'package:flutter/material.dart';
import '../models/reminder_status.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'date_carousel.dart';

// Функция группировки напоминаний по времени теперь работает с разными типами напоминаний
// reminder_widgets.dart

Map<String, List<Map<String, dynamic>>> groupRemindersByTime(
    List<Map<String, dynamic>> reminders) {
  Map<String, List<Map<String, dynamic>>> grouped = {};
  for (var reminder in reminders) {
    String time = reminder['selectTime'] ?? 'Не указано';
    if (!grouped.containsKey(time)) {
      grouped[time] = [];
    }
    grouped[time]!.add(reminder);
  }
  return grouped;
}

// Виджет для отображения группы напоминаний в определенное время
// reminder_widgets.dart

Widget buildReminderGroup(
  String time,
  List<Map<String, dynamic>> reminders,
  DateTime selectedDate,
  Map<int, Map<DateTime, ReminderStatus>> reminderStatuses,
  Function loadReminders,
  GlobalKey<DateCarouselState> dateCarouselKey, // Указываем тип
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0B102B),
              ),
            ),
            InkWell(
              onTap: () async {
                print('Accepting all reminders for time: $time');
                for (var reminder in reminders) {
                  final reminderId = reminder['id'];
                  reminderStatuses[reminderId]?[DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                  )] = ReminderStatus.complete;
                }
                loadReminders();
                dateCarouselKey.currentState
                    ?.updateCarousel(); // Теперь работает
              },
              child: const Text(
                "Принять все",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF197FF2),
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: reminders.map((reminder) {
            if (reminder.containsKey('type') &&
                reminder['type'] == 'measurement') {
              return buildMeasurementTile(
                reminder,
                selectedDate,
                dateCarouselKey,
              );
            } else if (reminder.containsKey('type') &&
                reminder['type'] == 'action') {
              return buildActionTile(
                reminder,
                selectedDate,
                dateCarouselKey,
              );
            } else {
              return buildReminderTile(
                reminder,
                selectedDate,
                reminderStatuses,
                loadReminders,
                dateCarouselKey,
              );
            }
          }).toList(),
        ),
      ),
    ],
  );
}

// reminder_widgets.dart
Widget buildMeasurementTile(
  Map<String, dynamic> measurement,
  DateTime selectedDate,
  GlobalKey<DateCarouselState> dateCarouselKey, // Указываем тип
) {
  final name = measurement['name'] ?? 'Название не указано';
  final mealTime = measurement['mealTime'] ?? 'Время приема не указано';

  return ListTile(
    title: Text(
      name,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0B102B),
      ),
    ),
    subtitle: Text(
      mealTime,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6B7280),
      ),
    ),
    trailing: Icon(Icons.arrow_forward_ios_rounded), // Стрелочка вместо галочки
  );
}

Widget buildActionTile(
  Map<String, dynamic> action,
  DateTime selectedDate,
  GlobalKey<DateCarouselState> dateCarouselKey, // Указываем тип
) {
  final name = action['name'] ?? 'Название не указано';
  final mealTime = action['mealTime'] ?? 'Время приема не указано';

  return ListTile(
    title: Text(
      name,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0B102B),
      ),
    ),
    subtitle: Text(
      mealTime,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF6B7280),
      ),
    ),
    trailing: Icon(Icons.arrow_forward_ios_rounded), // Стрелочка вместо галочки
  );
}

// Виджет для отображения одного напоминания, действия или измерения
Widget buildReminderTile(
  Map<String, dynamic> reminder,
  DateTime selectedDate,
  Map<int, Map<DateTime, ReminderStatus>> reminderStatuses,
  Function loadReminders,
  GlobalKey<DateCarouselState> dateCarouselKey, // Указываем тип
) {
  final reminderId = reminder['id'];
  final status = reminderStatuses[reminderId]?[DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      )] ??
      ReminderStatus.none;
  bool isCompleted = status == ReminderStatus.complete;

  // Определяем название напоминания в зависимости от типа напоминания
  String name = '';
  if (reminder.containsKey('type')) {
    name = reminder['type'] ?? 'Тип не указан';
  } else {
    name = reminder['name'] ?? 'Название не указано';
  }

  // Формируем строку для subtitle в зависимости от наличия 'dosage'
  String subtitleText = '${reminder['time']}, ${reminder['unit']}';
  if (reminder.containsKey('dosage')) {
    subtitleText =
        '${reminder['time']}, ${reminder['dosage']} ${reminder['unit']}';
  }

  return ListTile(
    title: Text(
      name,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isCompleted ? Colors.grey : const Color(0xFF0B102B),
      ),
    ),
    subtitle: Text(
      subtitleText,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isCompleted ? Colors.grey : const Color(0xFF6B7280),
      ),
    ),
    trailing: Checkbox(
      value: isCompleted,
      onChanged: (bool? value) async {
        await DatabaseService.updateReminderCompletionStatus(
          reminderId,
          value ?? false,
          selectedDate,
        );
        loadReminders();
        dateCarouselKey.currentState?.updateCarousel(); // Теперь работает
      },
      shape: const CircleBorder(),
      activeColor: const Color(0xFF197FF2),
      checkColor: Colors.white,
    ),
  );
}
