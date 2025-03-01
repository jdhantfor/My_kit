import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'today/empty_state_widget.dart';
import 'database_service.dart';
import 'profile_screen.dart';
import 'user_provider.dart';
import 'today/date_carousel.dart';
import 'models/reminder_status.dart';
import 'today/notification_screen.dart';
import 'overview_screen.dart';
import 'add_lechenie/treatment_details_screen.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  _TodayScreenState createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _actions = [];
  List<Map<String, dynamic>> _measurements = [];
  final GlobalKey<DateCarouselState> _dateCarouselKey =
      GlobalKey<DateCarouselState>();
  Map<int, Map<DateTime, ReminderStatus>> _reminderStatuses = {};
  Map<int, bool> _localReminderStatuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData().then((_) {
      updateReminderStatuses();
      print('Initial data loaded and statuses updated');
    });
  }

  Future<void> _loadData() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final databaseService = DatabaseService();
      final remindersRaw =
          await databaseService.getRemindersByDate(userId, _selectedDate);
      final actionsRaw =
          await databaseService.getActionsByDate(userId, _selectedDate);
      final measurementsRaw =
          await databaseService.getMeasurementsByDate(userId, _selectedDate);

      setState(() {
        _reminders = remindersRaw
            .map((r) => {...r, 'type': r['type'] ?? 'tablet'})
            .toList();
        _actions = actionsRaw.map((a) => {...a, 'type': 'action'}).toList();
        _measurements =
            measurementsRaw.map((m) => {...m, 'type': 'measurement'}).toList();

        _localReminderStatuses = {};
        for (var reminder in _reminders) {
          final reminderId = reminder['id'];
          final status = _reminderStatuses[reminderId]?[DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              )] ??
              ReminderStatus.none;
          _localReminderStatuses[reminderId] =
              status == ReminderStatus.complete;
          print(
              'Initialized local status for reminder $reminderId: ${_localReminderStatuses[reminderId]}');
        }
      });

      await updateReminderStatuses();
      print('Data loaded: ${_reminders.length} reminders, ${_actions.length} actions, ${_measurements.length} measurements');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Map<DateTime, ReminderStatus> calculateDateStatuses(
    List<Map<String, dynamic>> reminders,
    Map<int, Map<DateTime, ReminderStatus>> reminderStatuses,
  ) {
    Map<DateTime, ReminderStatus> dateStatuses = {};
    for (var reminder in reminders) {
      int reminderId = reminder['id'];
      var statusesForReminder = reminderStatuses[reminderId];
      if (statusesForReminder != null) {
        statusesForReminder.forEach((date, status) {
          if (!dateStatuses.containsKey(date)) {
            dateStatuses[date] = status;
          } else if (status == ReminderStatus.incomplete) {
            dateStatuses[date] = ReminderStatus.incomplete;
          }
        });
      }
    }
    print('Calculated date statuses: $dateStatuses');
    return Map<DateTime, ReminderStatus>.from(dateStatuses);
  }

  Future<void> _loadReminders() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final databaseService = DatabaseService();
      final reminders =
          await databaseService.getRemindersByDate(userId, _selectedDate);
      setState(() {
        _reminders = reminders
            .map((reminder) => Map<String, dynamic>.from(reminder))
            .toList();
      });
      print('Reminders reloaded: ${_reminders.length} reminders');
    }
  }

  Future<void> updateReminderStatuses() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final DateTime now = DateTime.now();
      final DateTime fifteenDaysAgo = now.subtract(const Duration(days: 15));
      final List<DateTime> allDatesInCarousel = List.generate(
        31,
        (index) => fifteenDaysAgo.add(Duration(days: index)),
      );

      final databaseService = DatabaseService();
      final rawStatuses = await databaseService.getReminderStatusesForDates(
          userId, allDatesInCarousel);

      print('Raw statuses from database: $rawStatuses');

      setState(() {
        _reminderStatuses = {};
        rawStatuses.forEach((reminderId, dateStatusMap) {
          if (_reminderStatuses[reminderId] == null) {
            _reminderStatuses[reminderId] = {};
          }
          dateStatusMap.forEach((date, isCompleted) {
            _reminderStatuses[reminderId]![
                    DateTime(date.year, date.month, date.day)] =
                isCompleted == null
                    ? ReminderStatus.none
                    : (isCompleted == true
                        ? ReminderStatus.complete
                        : ReminderStatus.incomplete);
          });
        });
      });

      print('Updated reminder statuses: $_reminderStatuses');
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadData();
    print('Date selected: $date');
  }

  // Перенесенная функция groupRemindersByTime
  Map<String, List<Map<String, dynamic>>> groupRemindersByTime(
      List<Map<String, dynamic>> reminders) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var reminder in reminders) {
      print('Grouping reminder: $reminder');
      String time = reminder['selectTime'] ?? 'Не указано';
      if (!grouped.containsKey(time)) {
        grouped[time] = [];
      }
      grouped[time]!.add(reminder);
    }

    print('Grouped reminders: $grouped');
    return grouped;
  }

  Widget buildReminderGroup(
  BuildContext context,
  String time,
  List<Map<String, dynamic>> reminders,
  DateTime selectedDate,
  Map<int, Map<DateTime, ReminderStatus>> reminderStatuses,
  Function loadReminders,
  GlobalKey<DateCarouselState> dateCarouselKey,
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
            if (reminders.any((r) => r['type'] == 'tablet' || r['type'] == 'action'))
              TextButton(
                onPressed: () async {
                  print('Marking all reminders at $time as completed');
                  final userId =
                      Provider.of<UserProvider>(context, listen: false).userId;
                  if (userId != null) {
                    final databaseService = DatabaseService();
                    for (var reminder in reminders) {
                      if (reminder['type'] == 'tablet' ||
                          reminder['type'] == 'action') {
                        final reminderId = reminder['id'] as int;
                        await databaseService.updateReminderCompletionStatus(
                          reminderId,
                          true,
                          selectedDate,
                        );
                        print(
                            'Marked reminder $reminderId at $time as completed');
                        // Обновляем локальный статус немедленно
                        setState(() {
                          _localReminderStatuses[reminderId] = true;
                        });
                      }
                    }
                    await loadReminders();
                    dateCarouselKey.currentState?.updateCarousel();
                  }
                },
                child: const Text(
                  'Принять все',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF197FF2), // Синий цвет, как на картинке
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
          children: reminders
              .map((reminder) => buildReminderTile(
                    context,
                    reminder,
                    selectedDate,
                    reminderStatuses,
                    loadReminders,
                    dateCarouselKey,
                    _localReminderStatuses,
                    (int id, bool value) {
                      setState(() {
                        _localReminderStatuses[id] = value;
                      });
                      print('Local status updated for reminder $id: $value');
                    },
                  ))
              .toList(),
        ),
      ),
    ],
  );
}

  Widget buildReminderTile(
  BuildContext context,
  Map<String, dynamic> reminder,
  DateTime selectedDate,
  Map<int, Map<DateTime, ReminderStatus>> reminderStatuses,
  Function loadReminders,
  GlobalKey<DateCarouselState> dateCarouselKey,
  Map<int, bool> localReminderStatuses,
  Function(int, bool) onStatusChanged,
) {
  final reminderId = reminder['id'];
  final type = reminder['type'] ?? 'tablet';
  bool isCompleted = localReminderStatuses[reminderId] ?? false;

  String name = reminder['name'] ?? 'Название не указано';
  String subtitleText = '';

  if (type == 'tablet') {
    if (reminder.containsKey('dosage') && reminder.containsKey('unit')) {
      subtitleText = '${reminder['dosage']} ${reminder['unit']}';
    }
    if (reminder.containsKey('time')) {
      subtitleText += ' - ${reminder['time']}';
      print('time for reminder $reminderId: ${reminder['time']}');
    } else {
      print('No time found for reminder $reminderId');
    }
  } else if (type == 'action' || type == 'measurement') {
    subtitleText = reminder['time'] ?? '';
    print('Subtitle for reminder $reminderId (type: $type): $subtitleText');
  }

  Widget trailingWidget;
  if (type == 'tablet' || type == 'action') {
    trailingWidget = Checkbox(
      value: isCompleted,
      onChanged: (bool? value) async {
        if (value != null) {
          print('Updating local status for reminder $reminderId to $value');
          onStatusChanged(reminderId, value);

          final databaseService = DatabaseService();
          try {
            await databaseService.updateReminderCompletionStatus(
              reminderId,
              value,
              selectedDate,
            );
            print(
                'Successfully updated reminder status in database for $reminderId');
            await loadReminders();
            dateCarouselKey.currentState?.updateCarousel();
          } catch (e) {
            print('Error updating reminder status in database: $e');
            onStatusChanged(reminderId, !value);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ошибка при обновлении статуса')),
            );
          }
        }
      },
      shape: const CircleBorder(),
      activeColor: const Color(0xFF197FF2),
      checkColor: Colors.white,
    );
  } else {
    trailingWidget = const Icon(Icons.arrow_forward_ios_rounded);
  }

  // Добавляем кнопку с названием курса, если есть courseid и тип не 'measurement', и courseid != -1
  Widget courseButton = const SizedBox.shrink(); // Пустой виджет по умолчанию
  if (reminder.containsKey('courseid') &&
      type != 'measurement' &&
      reminder['courseid'] != -1) {
    final courseId = reminder['courseid'] as int;
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      courseButton = FutureBuilder<String>(
        future: DatabaseService.getCourseName(courseId, userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink(); // Показываем пустой виджет, пока данные загружаются
          }
          if (snapshot.hasError) {
            print('Error loading course name: ${snapshot.error}');
            return const SizedBox.shrink();
          }
          final courseName = snapshot.data ?? 'Курс';
          return GestureDetector(
            onTap: () {
              print('Navigating to TreatmentDetailsScreen for course $courseId');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TreatmentDetailsScreen(
                    course: {
                      'id': courseId,
                      'name': courseName,
                      'startDate': reminder['startDate'], // Можно уточнить, если нужно
                      'endDate': reminder['endDate'], // Можно уточнить, если нужно
                    },
                    userId: userId,
                    color: const Color(0xFF6B48FF), // Фиолетовый цвет, как у кнопки
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: const Color(0xFF6B48FF), // Фиолетовый цвет, как на картинке
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    courseName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  return ListTile(
    title: Row(
      children: [
        Flexible(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isCompleted ? Colors.grey : const Color(0xFF0B102B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8.0), // Добавляем отступ между именем и кнопкой
        courseButton, // Добавляем кнопку курса
      ],
    ),
    subtitle: Text(
      subtitleText,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isCompleted ? Colors.grey : const Color(0xFF6B7280),
      ),
    ),
    trailing: trailingWidget,
    onTap: type == 'measurement'
        ? () {
            print('Navigating to OverviewScreen');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OverviewScreen(),
              ),
            );
          }
        : null,
  );
}
  // Перенесенная функция buildCircularIconButton
  Widget buildCircularIconButton({
    required String iconAsset,
    required VoidCallback onPressed,
    double size = 38,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            iconAsset,
            width: size - 16,
            height: size - 16,
          ),
        ),
      ),
    );
  }

 @override
Widget build(BuildContext context) {
  final allReminders = <Map<String, dynamic>>[];
  allReminders.addAll(_reminders);
  allReminders.addAll(_actions);
  allReminders.addAll(_measurements);

  final groupedReminders = groupRemindersByTime(allReminders);

  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text(
        'Моё расписание',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0B102B),
        ),
      ),
      actions: [
        buildCircularIconButton(
          iconAsset: 'assets/prof.png',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ).then((_) {
              _dateCarouselKey.currentState?.scrollToToday();
            });
          },
          size: 36,
        ),
        const SizedBox(width: 6),
        buildCircularIconButton(
          iconAsset: 'assets/noti.png',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationsScreen()),
            );
          },
          size: 36,
        ),
        const SizedBox(width: 20),
      ],
    ),
    body: Column(
      children: [
        DateCarousel(
          key: _dateCarouselKey,
          selectedDate: _selectedDate,
          onDateSelected: _onDateSelected,
          reminderStatuses:
              calculateDateStatuses(_reminders, _reminderStatuses),
        ),
        Expanded(
          child: allReminders.isNotEmpty
              ? ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  children: groupedReminders.entries
                      .map((entry) => buildReminderGroup(
                            context,
                            entry.key,
                            entry.value,
                            _selectedDate,
                            _reminderStatuses,
                            _loadReminders,
                            _dateCarouselKey,
                          ))
                      .toList(),
                )
              : const EmptyStateWidget(),
        ),
      ],
    ),
  );
}
}