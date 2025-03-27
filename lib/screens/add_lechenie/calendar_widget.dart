import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/models/reminder_status.dart';
import 'package:my_aptechka/screens/add_lechenie/check_list_screen.dart';

class CalendarWidget extends StatefulWidget {
  final int courseId;
  final String userId;

  const CalendarWidget({
    super.key,
    required this.courseId,
    required this.userId,
  });

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _actions = [];
  DateTime? _earliestStartDate;
  DateTime? _latestEndDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final databaseService = DatabaseService();
      final reminders = await databaseService.getRemindersByCourseId(
          widget.courseId, widget.userId);
      final measurements = await DatabaseService.getMeasurements(widget.userId)
          .then((list) =>
              list.where((m) => m['courseid'] == widget.courseId).toList());
      final actions = await DatabaseService.getActions(widget.userId).then(
          (list) =>
              list.where((a) => a['courseid'] == widget.courseId).toList());

      DateTime? earliestStart;
      DateTime? latestEnd;

      for (final reminder in reminders) {
        final startDate = DateTime.parse(reminder['startDate']);
        final endDate = reminder['endDate'] != null
            ? DateTime.parse(reminder['endDate'])
            : null;
        final isLifelong = reminder['isLifelong'] == 1;

        if (earliestStart == null || startDate.isBefore(earliestStart)) {
          earliestStart = startDate;
        }
        if (isLifelong) {
          latestEnd = DateTime.now();
        } else if (endDate != null &&
            (latestEnd == null || endDate.isAfter(latestEnd))) {
          latestEnd = endDate;
        }
      }

      for (final measurement in measurements) {
        final startDate = DateTime.parse(measurement['startDate']);
        final endDate = measurement['endDate'] != null
            ? DateTime.parse(measurement['endDate'])
            : null;
        final isLifelong = measurement['isLifelong'] == 1;

        if (earliestStart == null || startDate.isBefore(earliestStart)) {
          earliestStart = startDate;
        }
        if (isLifelong) {
          if (latestEnd == null || DateTime.now().isAfter(latestEnd)) {
            latestEnd = DateTime.now();
          }
        } else if (endDate != null &&
            (latestEnd == null || endDate.isAfter(latestEnd))) {
          latestEnd = endDate;
        }
      }

      for (final action in actions) {
        final startDate = DateTime.parse(action['startDate']);
        final endDate = action['endDate'] != null
            ? DateTime.parse(action['endDate'])
            : null;
        final isLifelong = action['isLifelong'] == 1;

        if (earliestStart == null || startDate.isBefore(earliestStart)) {
          earliestStart = startDate;
        }
        if (isLifelong) {
          if (latestEnd == null || DateTime.now().isAfter(latestEnd)) {
            latestEnd = DateTime.now();
          }
        } else if (endDate != null &&
            (latestEnd == null || endDate.isAfter(latestEnd))) {
          latestEnd = endDate;
        }
      }

      setState(() {
        _reminders = reminders;
        _actions = actions;
        _earliestStartDate = earliestStart;
        _latestEndDate = latestEnd;
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        ..._buildMonthBlocks(),
      ],
    );
  }

  List<Widget> _buildMonthBlocks() {
    final List<Widget> monthBlocks = [];

    if (_earliestStartDate == null || _latestEndDate == null) {
      return monthBlocks;
    }

    DateTime currentDate =
        DateTime(_earliestStartDate!.year, _earliestStartDate!.month);
    final endDate = DateTime(_latestEndDate!.year, _latestEndDate!.month + 1);

    while (currentDate.isBefore(endDate)) {
      monthBlocks.add(_buildMonthBlock(currentDate));
      currentDate = DateTime(currentDate.year, currentDate.month + 1);
    }

    return monthBlocks;
  }

  Widget _buildMonthBlock(DateTime monthDate) {
    final monthNames = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    final monthName = monthNames[monthDate.month - 1];
    final formattedMonth = '$monthName ${monthDate.year}';
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final weekDays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    final List<Widget> dayWidgets = [];

    for (int i = firstDayOfMonth.weekday; i > 1; i--) {
      dayWidgets.add(const SizedBox(width: 42));
    }

    for (DateTime date = firstDayOfMonth;
        date.isBefore(lastDayOfMonth.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      dayWidgets.add(_buildDayTile(date));
    }

    for (int i = 0; i < 7 - (lastDayOfMonth.weekday + 1); i++) {
      dayWidgets.add(const SizedBox(width: 42));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedMonth,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDays
                  .map((day) => Text(day, style: const TextStyle(fontSize: 14)))
                  .toList(),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: dayWidgets,
            ),
          ],
        ),
      ),
    );
  }

  Future<Color> _getDayColor(DateTime date) async {
    final databaseService = DatabaseService();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    print('Checking day: $normalizedDate');

    bool isWithinCourseRange =
        (_earliestStartDate != null && _latestEndDate != null) &&
            (normalizedDate.isAfter(
                    _earliestStartDate!.subtract(const Duration(days: 1))) &&
                normalizedDate
                    .isBefore(_latestEndDate!.add(const Duration(days: 1))));

    if (!isWithinCourseRange) {
      print('Day $normalizedDate is outside course range, color: grey');
      return Colors.grey;
    } else if (normalizedDate.isAfter(today)) {
      print('Day $normalizedDate is in future, color: black');
      return Colors.black;
    }

    final reminders = _reminders.where((r) {
      final start = DateTime.parse(r['startDate']);
      final end = r['endDate'] != null ? DateTime.parse(r['endDate']) : null;
      final isLifelong = r['isLifelong'] == 1;
      return normalizedDate.isAfter(start.subtract(const Duration(days: 1))) &&
          (isLifelong ||
              (end != null &&
                  normalizedDate.isBefore(end.add(const Duration(days: 1)))));
    }).toList();

    final actions = _actions.where((a) {
      final start = DateTime.parse(a['startDate']);
      final end = a['endDate'] != null ? DateTime.parse(a['endDate']) : null;
      final isLifelong = a['isLifelong'] == 1;
      return normalizedDate.isAfter(start.subtract(const Duration(days: 1))) &&
          (isLifelong ||
              (end != null &&
                  normalizedDate.isBefore(end.add(const Duration(days: 1)))));
    }).toList();

    print('Reminders for $normalizedDate: $reminders');
    print('Actions for $normalizedDate: $actions');

    if (reminders.isEmpty && actions.isEmpty) {
      print('No tasks for $normalizedDate, color: green');
      return Colors.green;
    }

    int totalTasks = reminders.length + actions.length;
    int completedTasks = 0;

    print('Total tasks for $normalizedDate: $totalTasks');

    for (final reminder in reminders) {
      final status = await databaseService.getReminderStatusForDate(
          reminder['id'], normalizedDate);
      print('Reminder ${reminder['id']} status: $status');
      if (status == ReminderStatus.complete) {
        completedTasks++;
      }
    }

    for (final action in actions) {
      final status = await databaseService.getActionStatusForDate(
          action['id'], normalizedDate);
      print('Action ${action['id']} status: $status');
      if (status == ReminderStatus.complete) {
        completedTasks++;
      }
    }

    print('Completed tasks for $normalizedDate: $completedTasks');

    if (completedTasks == totalTasks && totalTasks > 0) {
      print('All tasks completed for $normalizedDate, color: green');
      return Colors.green;
    } else if (completedTasks > 0) {
      print('Some tasks completed for $normalizedDate, color: yellow');
      return Colors.yellow;
    } else {
      print('No tasks completed for $normalizedDate, color: red');
      return Colors.red;
    }
  }

  Widget _buildDayTile(DateTime date) {
    return FutureBuilder<Color>(
      future: _getDayColor(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 42,
            height: 42,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final color = snapshot.data ?? Colors.black;

        return GestureDetector(
          onTap: () async {
            // Переход на экран чеклиста при нажатии
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChecklistScreen(
                  date: date,
                  courseId: widget.courseId,
                  userId: widget.userId,
                ),
              ),
            );
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(child: SingleChildScrollView(child: _buildCalendar())),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                const Flexible(
                  child: Text(
                    'Выполнены все',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                const Flexible(
                  child: Text(
                    'Выполнено частично',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                const Flexible(
                  child: Text(
                    'Ничего не выполнено',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.left,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
