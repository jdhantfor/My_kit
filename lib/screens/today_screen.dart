import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'today/empty_state_widget.dart';
import 'today/completed_state_widget.dart';
import 'database_service.dart';
import 'profile_screen.dart';
import 'user_provider.dart';
import 'today/date_carousel.dart';
import 'models/reminder_status.dart';
import 'today/notification_screen.dart';
import 'add_lechenie/treatment_details_screen.dart';

class TodayScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const TodayScreen({super.key, this.onTabChange});

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
  bool _isUpdating = false;
  bool _hasAnyData = false;
  bool _showCompletedState = false;
  bool _hasNotifications = false; // Новая переменная для уведомлений

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    _checkNotifications(); // Проверяем уведомления при инициализации
  }

  Future<void> _loadInitialData() async {
    await _checkIfAnyDataExists();
    await _loadReminders();
    await updateReminderStatuses();
    await _loadData();
    _checkIfAllTasksCompleted();
    setState(() {});
  }

  // Метод для проверки наличия уведомлений
  Future<void> _checkNotifications() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userEmail = userProvider.email;
    final isSubscribed = userProvider.subscribe; // Проверяем статус подписки

    // Если пользователь не подписан, сразу устанавливаем _hasNotifications в true
    if (!isSubscribed) {
      setState(() {
        _hasNotifications = true;
      });
      return;
    }

    // Если пользователь подписан, проверяем только приглашения
    if (userEmail == null || userEmail.isEmpty) {
      setState(() {
        _hasNotifications = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://62.113.37.96:5002/invitations?email=$userEmail'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final invitations = data['invitations'] as List<dynamic>;
        setState(() {
          _hasNotifications = invitations.isNotEmpty;
        });
      } else {
        setState(() {
          _hasNotifications = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasNotifications = false;
      });
    }
  }

  void _checkIfAllTasksCompleted() {
    final allApplicableReminders = [
      ..._reminders.where((r) => r['type'] == 'tablet'),
      ..._actions.where((r) => r['type'] == 'action'),
    ];

    if (allApplicableReminders.isNotEmpty) {
      bool allCompleted = allApplicableReminders.every((reminder) {
        final reminderId = reminder['id'];
        return _localReminderStatuses[reminderId] == true;
      });
      setState(() {
        _showCompletedState = allCompleted;
      });
    } else {
      setState(() {
        _showCompletedState = false;
      });
    }
  }

  Future<void> _checkIfAnyDataExists() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final databaseService = DatabaseService();
      final reminders = await databaseService.getReminders(userId);
      final actions = await DatabaseService.getActions(userId);
      final measurements = await DatabaseService.getMeasurements(userId);

      setState(() {
        _hasAnyData = reminders.isNotEmpty ||
            actions.isNotEmpty ||
            measurements.isNotEmpty;
      });
    }
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
        for (var reminder in [..._reminders, ..._actions]) {
          final reminderId = reminder['id'];
          final normalizedDate = DateTime(
              _selectedDate.year, _selectedDate.month, _selectedDate.day);
          final status = _reminderStatuses[reminderId]?[normalizedDate] ??
              ReminderStatus.none;
          _localReminderStatuses[reminderId] =
              status == ReminderStatus.complete;
        }
      });

      _checkIfAllTasksCompleted();

      print(
          'Loaded data - Reminders: ${_reminders.length}, Actions: ${_actions.length}, Measurements: ${_measurements.length}');
      _dateCarouselKey.currentState?.updateCarousel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Map<DateTime, DayStatus> calculateDateStatuses(
    List<Map<String, dynamic>> reminders,
    List<Map<String, dynamic>> actions,
    Map<int, Map<DateTime, ReminderStatus>> reminderStatuses,
  ) {
    Map<DateTime, DayStatus> dateStatuses = {};
    final today = DateTime.now();

    final allApplicableReminders = [
      ...reminders.where((r) => r['type'] == 'tablet'),
      ...actions.where((r) => r['type'] == 'action'),
    ];

    if (allApplicableReminders.isEmpty) {
      return dateStatuses;
    }

    Map<DateTime, List<Map<String, dynamic>>> remindersByDate = {};
    for (var reminder in allApplicableReminders) {
      final reminderId = reminder['id'];
      final statuses = reminderStatuses[reminderId] ?? {};
      Set<DateTime> uniqueDates = {};
      for (var date in statuses.keys) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        uniqueDates.add(normalizedDate);
      }
      for (var date in uniqueDates) {
        final startDate = DateTime.parse(reminder['startDate']);
        final endDate = reminder['endDate'] != null
            ? DateTime.parse(reminder['endDate'])
            : null;
        final isLifelong = reminder['isLifelong'] == 1;
        final scheduleType = reminder['schedule_type'] ?? 'daily';
        bool isScheduledDay = false;

        if (date.isBefore(startDate) ||
            (endDate != null && date.isAfter(endDate) && !isLifelong)) {
          continue;
        }

        if (scheduleType == 'daily') {
          isScheduledDay = true;
        } else if (scheduleType == 'interval') {
          final intervalValue = reminder['interval_value'] ?? 1;
          final daysSinceStart = date.difference(startDate).inDays;
          isScheduledDay = daysSinceStart % intervalValue == 0;
        } else if (scheduleType == 'weekly') {
          final selectedDaysMask = reminder['selected_days_mask'] ?? 0;
          final dayOfWeek = date.weekday % 7;
          isScheduledDay = (selectedDaysMask & (1 << dayOfWeek)) != 0;
        } else if (scheduleType == 'cyclic') {
          final cycleDuration = reminder['cycle_duration'] ?? 1;
          final cycleBreak = reminder['cycle_break'] ?? 0;
          final totalCycle = cycleDuration + cycleBreak;
          final daysSinceStart = date.difference(startDate).inDays;
          isScheduledDay = (daysSinceStart % totalCycle) < cycleDuration;
        } else if (scheduleType == 'single') {
          isScheduledDay = date == startDate;
        }

        if (!isScheduledDay) {
          continue;
        }

        final status = statuses[date] ?? ReminderStatus.incomplete;
        if (!remindersByDate.containsKey(date)) {
          remindersByDate[date] = [];
        }
        if (!remindersByDate[date]!.any((r) => r['id'] == reminderId)) {
          remindersByDate[date]!.add(reminder);
        }
      }
    }

    remindersByDate.forEach((date, dateReminders) {
      int totalApplicable = dateReminders.length;
      int completed = 0;
      int incomplete = 0;

      for (var reminder in dateReminders) {
        final reminderId = reminder['id'];
        final normalizedDate = DateTime(date.year, date.month, date.day);
        ReminderStatus status = reminderStatuses[reminderId]?[normalizedDate] ??
            ReminderStatus.incomplete;
        if (status == ReminderStatus.complete) {
          completed++;
        } else if (status == ReminderStatus.incomplete) {
          incomplete++;
        }
      }

      if (totalApplicable == 0) {
      } else if (completed == totalApplicable) {
        dateStatuses[date] = DayStatus.green;
      } else if (completed > 0 && incomplete > 0) {
        dateStatuses[date] = DayStatus.yellow;
      } else {
        dateStatuses[date] = DayStatus.red;
      }
    });

    return dateStatuses;
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
      final Map<int, Map<DateTime, ReminderStatus>> rawStatuses =
          await databaseService.getReminderStatusesForDates(
              userId, allDatesInCarousel);

      setState(() {
        _reminderStatuses = rawStatuses;
      });
    }
  }

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

  Widget buildReminderGroup(
    BuildContext context,
    String time,
    List<Map<String, dynamic>> reminders,
    DateTime selectedDate,
    Map<int, Map<DateTime, ReminderStatus>> reminderStatuses,
    Function loadReminders,
    GlobalKey<DateCarouselState> dateCarouselKey,
  ) {
    final today = DateTime.now();
    final isPastOrToday = selectedDate.year < today.year ||
        (selectedDate.year == today.year && selectedDate.month < today.month) ||
        (selectedDate.year == today.year &&
            selectedDate.month == today.month &&
            selectedDate.day <= today.day);

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
              if (reminders
                  .any((r) => r['type'] == 'tablet' || r['type'] == 'action'))
                TextButton(
                  onPressed: isPastOrToday && !_isUpdating
                      ? () async {
                          final userId =
                              Provider.of<UserProvider>(context, listen: false)
                                  .userId;
                          if (userId != null) {
                            final databaseService = DatabaseService();
                            _isUpdating = true;
                            bool hasError = false;
                            String? errorMessage;

                            for (var reminder in reminders.where((r) =>
                                r['type'] == 'tablet' ||
                                r['type'] == 'action')) {
                              final reminderId = reminder['id'] as int;
                              try {
                                await databaseService
                                    .updateReminderCompletionStatus(
                                  reminderId,
                                  true,
                                  selectedDate,
                                );
                                setState(() {
                                  _reminderStatuses[reminderId] ??= {};
                                  _reminderStatuses[reminderId]![DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                  )] = ReminderStatus.complete;
                                  _localReminderStatuses[reminderId] = true;
                                });
                              } catch (e) {
                                hasError = true;
                                errorMessage = e.toString();
                              }
                            }

                            if (hasError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Ошибка при обновлении: $errorMessage')),
                              );
                            }
                            _isUpdating = false;
                            dateCarouselKey.currentState?.updateCarousel();
                            _checkIfAllTasksCompleted();
                          }
                        }
                      : null,
                  child: const Text(
                    'Принять все',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
  final today = DateTime.now();
  final isPastOrToday = selectedDate.year < today.year ||
      (selectedDate.year == today.year && selectedDate.month < today.month) ||
      (selectedDate.year == today.year &&
          selectedDate.month == today.month &&
          selectedDate.day <= today.day);

  if (!_localReminderStatuses.containsKey(reminderId)) {
    final normalizedDate =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    ReminderStatus status = ReminderStatus.none;
    if (reminderStatuses[reminderId] != null) {
      status = reminderStatuses[reminderId]![normalizedDate] ??
          ReminderStatus.none;
    }
    _localReminderStatuses[reminderId] = status == ReminderStatus.complete;
  }


    String name = reminder['name'] ?? 'Название не указано';
    String subtitleText = '';

    if (type == 'tablet') {
      if (reminder.containsKey('dosage') && reminder.containsKey('unit')) {
        subtitleText = '${reminder['dosage']} ${reminder['unit']}';
      }
      if (reminder.containsKey('time')) {
        subtitleText += ' - ${reminder['time']}';
      }
    } else if (type == 'action' || type == 'measurement') {
      subtitleText = reminder['time'] ?? '';
    }

    Widget trailingWidget;
    if (type == 'tablet' || type == 'action') {
      trailingWidget = Checkbox(
    value: isCompleted,
    onChanged: isPastOrToday && !_isUpdating
        ? (bool? value) async {
            if (value != null) {
              _isUpdating = true;
              onStatusChanged(reminderId, value);
              final databaseService = DatabaseService();
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              try {
                await databaseService.updateReminderCompletionStatus(
                  reminderId,
                  value,
                  selectedDate,
                );
                setState(() {
                  _reminderStatuses[reminderId] ??= {};
                  _reminderStatuses[reminderId]![DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                  )] = value ? ReminderStatus.complete : ReminderStatus.incomplete;
                  _localReminderStatuses[reminderId] = value;
                });
                _dateCarouselKey.currentState?.updateCarousel();
                _checkIfAllTasksCompleted();
                // Уведомляем о изменении лекарств
                userProvider.notifyMedicineChanged();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка при обновлении: $e')),
                );
                onStatusChanged(reminderId, !value);
              } finally {
                _isUpdating = false;
              }
            }
          }
        : null,
    shape: const CircleBorder(),
    activeColor: const Color(0xFF197FF2),
    checkColor: Colors.white,
  );
    } else {
      trailingWidget = const Icon(Icons.arrow_forward_ios_rounded);
    }

    Widget courseButton = const SizedBox.shrink();
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
              return const SizedBox.shrink();
            }
            if (snapshot.hasError) {
              return const SizedBox.shrink();
            }
            final courseName = snapshot.data ?? 'Курс';
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreatmentDetailsScreen(
                      course: {
                        'id': courseId,
                        'name': courseName,
                        'startDate': reminder['startDate'],
                        'endDate': reminder['endDate'],
                      },
                      userId: userId,
                      color: const Color(0xFF6B48FF),
                    ),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B48FF),
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
          const SizedBox(width: 8.0),
          courseButton,
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
              widget.onTabChange?.call(3);
            }
          : null,
    );
  }

  Widget buildCircularIconButton({
    required String iconAsset,
    required VoidCallback onPressed,
    double size = 32,
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
          padding: const EdgeInsets.all(0),
          child: SvgPicture.asset(
            iconAsset,
            width: size,
            height: size,
          ),
        ),
      ),
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _showCompletedState = false;
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
    final reminderStatuses =
        calculateDateStatuses(_reminders, _actions, _reminderStatuses);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Моё расписание',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        actions: [
          buildCircularIconButton(
            iconAsset: 'assets/prof.svg',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) {
                _dateCarouselKey.currentState?.scrollToToday();
                setState(() {
                  _showCompletedState = false;
                });
              });
            },
            size: 32,
          ),
          const SizedBox(width: 6),
          buildCircularIconButton(
  iconAsset: _hasNotifications
      ? 'assets/noti_new.svg'
      : 'assets/noti.svg',
  onPressed: () {
    final userProvider =
        Provider.of<UserProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          userEmail: userProvider.email ?? '',
          onNotificationsUpdated: _checkNotifications,
        ),
      ),
    ).then((_) {
      setState(() {
        _showCompletedState = false;
      });
      _checkNotifications();
    });
  },
  size: 32,
),
          const SizedBox(width: 24),
        ],
      ),
      body: _hasAnyData
          ? Column(
              children: [
                DateCarousel(
                  key: _dateCarouselKey,
                  selectedDate: _selectedDate,
                  onDateSelected: _onDateSelected,
                  reminderStatuses: reminderStatuses,
                ),
                Expanded(
                  child: _showCompletedState
                      ? CompletedStateWidget(
                          onShowCompletedTasks: () {
                            setState(() {
                              _showCompletedState = false;
                            });
                          },
                        )
                      : allReminders.isNotEmpty
                          ? ListView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
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
                          : const Center(
                              child: Text(
                                'На эту дату нет напоминаний',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                ),
              ],
            )
          : const EmptyStateWidget(),
    );
  }
}