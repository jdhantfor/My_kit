import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/models/reminder_status.dart';

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
  late DateTime _selectedDate;
  List<Map<String, dynamic>> _reminders = [];
  Map<DateTime, ReminderStatus> _reminderStatuses = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadRemindersAndStatuses();
  }

  Future<void> _loadRemindersAndStatuses() async {
    try {
      final reminders = await DatabaseService.getRemindersByCourseId(
          widget.courseId, widget.userId);
      List<Map<String, dynamic>> tempReminders = [];
      Map<DateTime, ReminderStatus> tempReminderStatuses = {};
      for (final reminder in reminders) {
        final startDate = DateTime.parse(reminder['startDate']);
        final endDate = reminder['endDate'] != null
            ? DateTime.parse(reminder['endDate'])
            : null;
        final isLifelong = reminder['isLifelong'] == 1;
        if (!isLifelong && endDate != null) {
          for (var date = startDate;
              date.isBefore(endDate.add(Duration(days: 1)));
              date = date.add(Duration(days: 1))) {
            final status = await DatabaseService.getReminderStatusForDate(
                reminder['id'], date);
            tempReminderStatuses[date] = status ?? ReminderStatus.incomplete;
          }
        } else {
          final status = await DatabaseService.getReminderStatusForDate(
              reminder['id'], startDate);
          tempReminderStatuses[startDate] = status ?? ReminderStatus.incomplete;
        }
        tempReminders.add(reminder);
      }
      setState(() {
        _reminders = tempReminders;
        _reminderStatuses = tempReminderStatuses;
      });
    } catch (e) {
      print('Error loading reminders and statuses: $e');
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
    DateTime currentDate = DateTime(_selectedDate.year, _selectedDate.month);
    while (currentDate
        .isBefore(DateTime(_selectedDate.year + 1, _selectedDate.month + 2))) {
      monthBlocks.add(_buildMonthBlock(currentDate));
      currentDate = DateTime(currentDate.year, currentDate.month + 1);
    }
    return monthBlocks;
  }

  Widget _buildMonthBlock(DateTime monthDate) {
    final daysInMonth =
        DateFormat('MMMM yyyy', 'ru_RU').format(monthDate).capitalize();
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final weekDays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
    final List<Widget> dayWidgets = [];

    // Заполнение недель до начала месяца
    for (int i = firstDayOfMonth.weekday; i > 1; i--) {
      dayWidgets.add(const SizedBox(width: 42));
    }

    // Заполнение дней текущего месяца
    for (DateTime date = firstDayOfMonth;
        date.isBefore(lastDayOfMonth.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
      dayWidgets.add(_buildDayTile(date));
    }

    // Заполнение недель после конца месяца
    for (int i = 0; i < 7 - (lastDayOfMonth.weekday + 1); i++) {
      dayWidgets.add(const SizedBox(width: 42));
    }

    return Container(
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
              daysInMonth,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(color: Colors.grey), // Тонкая серая линия под заголовком
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDays
                  .map((day) => Text(day, style: TextStyle(fontSize: 14)))
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

  Widget _buildDayTile(DateTime date) {
    final status = _reminderStatuses[date];
    final color = status == ReminderStatus.complete
        ? Colors.green
        : status == ReminderStatus.incomplete
            ? Colors.red
            : Colors.orange;

    return GestureDetector(
      onTap: () {
        // Логика для нажатия на дату
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.transparent, // Белый фон без обводки
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            date.day.toString(),
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(child: SingleChildScrollView(child: _buildCalendar())),
          _buildLegend(), // Легенда закреплена снизу поверх самого календаря
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
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    'Выполнены все действия и измерения',
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
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
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
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
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

  Widget _buildLegendItem(Color color, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.left,
            maxLines: 2, // Ограничиваем количество строк для текста
            overflow:
                TextOverflow.ellipsis, // Добавляем многоточие при переполнении
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
