// today_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'today/empty_state_widget.dart';
import 'database_service.dart';
import 'profile_screen.dart';
import 'today/custom_dropdown.dart';
import 'user_provider.dart';
import 'today/date_carousel.dart'; // Импортируем DateCarousel из нового файла
import 'models/reminder_status.dart';
import 'today/notification_screen.dart';
import 'today/reminder_widgets.dart'; // Импортируем новые виджеты
import 'today/ui_components.dart'; // Импортируем UI компоненты

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  _TodayScreenState createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _actions = []; // Define actions
  List<Map<String, dynamic>> _measurements = []; // Define measurements
  final GlobalKey<DateCarouselState> _dateCarouselKey =
      GlobalKey<DateCarouselState>();
  Map<int, Map<DateTime, ReminderStatus>> _reminderStatuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData().then((_) {
      updateReminderStatuses(); // Обновляем статусы для всех дат
    });
  }

  Future<void> _loadData() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final databaseService = DatabaseService(); // Создаем экземпляр
      final remindersRaw =
          await databaseService.getRemindersByDate(userId, _selectedDate);
      final actionsRaw =
          await databaseService.getActionsByDate(userId, _selectedDate);
      final measurementsRaw =
          await databaseService.getMeasurementsByDate(userId, _selectedDate);

      setState(() {
        _reminders = remindersRaw
            .map((reminder) => Map<String, dynamic>.from(reminder))
            .toList();
        _actions = actionsRaw
            .map((action) => Map<String, dynamic>.from(action))
            .toList();
        _measurements = measurementsRaw
            .map((measurement) => Map<String, dynamic>.from(measurement))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadActions() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final databaseService = DatabaseService(); // Создаем экземпляр
      return await databaseService.getActionsByDate(userId, _selectedDate);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _loadMeasurements() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final databaseService = DatabaseService(); // Создаем экземпляр
      return await databaseService.getMeasurementsByDate(userId, _selectedDate);
    }
    return [];
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
    return Map<DateTime, ReminderStatus>.from(
        dateStatuses); // Преобразуем в изменяемый формат
  }

  Future<void> _loadReminders() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final databaseService = DatabaseService(); // Создаем экземпляр
      final reminders =
          await databaseService.getRemindersByDate(userId, _selectedDate);
      setState(() {
        _reminders = reminders
            .map((reminder) => Map<String, dynamic>.from(reminder))
            .toList();
      });
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

      final databaseService = DatabaseService(); // Создаем экземпляр
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
        title: CustomDropdown(
          items: const ['Моё расписание', 'Бабушка'],
          onSelected: (String result) {
            print('Выбрано: $result');
          },
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
                  builder: (context) => const NotificationsScreen(),
                ),
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
