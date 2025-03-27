import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/models/reminder_status.dart';

class ChecklistScreen extends StatefulWidget {
  final DateTime date;
  final int courseId;
  final String userId;

  const ChecklistScreen({
    super.key,
    required this.date,
    required this.courseId,
    required this.userId,
  });

  @override
  _ChecklistScreenState createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late List<Map<String, dynamic>> _reminders = [];
  late List<Map<String, dynamic>> _actions = [];
  late List<Map<String, dynamic>> _measurements = [];

  @override
  void initState() {
    super.initState();
    _loadChecklistData();
  }

  Future<void> _loadChecklistData() async {
    final databaseService = DatabaseService();
    final dateString = DateFormat('yyyy-MM-dd').format(widget.date);

    _reminders = await databaseService
        .getRemindersByDate(widget.userId, widget.date)
        .then((list) =>
            list.where((r) => r['courseid'] == widget.courseId).toList());
    _actions = await databaseService
        .getActionsByDate(widget.userId, widget.date)
        .then((list) =>
            list.where((a) => a['courseid'] == widget.courseId).toList());
    _measurements = await databaseService
        .getMeasurementsByDate(widget.userId, widget.date)
        .then((list) =>
            list.where((m) => m['courseid'] == widget.courseId).toList());

    setState(() {});
  }

  Widget _buildChecklistItem(Map<String, dynamic> item, bool isCompleted) {
    final databaseService = DatabaseService();
    final today = DateTime.now();
    final isPastOrToday = widget.date.year < today.year ||
        (widget.date.year == today.year && widget.date.month < today.month) ||
        (widget.date.year == today.year &&
            widget.date.month == today.month &&
            widget.date.day <= today.day);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          item['name'] ?? 'Без названия',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isCompleted ? Colors.grey : const Color(0xFF0B102B),
          ),
        ),
        subtitle: Text(
          item['dosage'] != null
              ? '${item['dosage']} ${item['unit'] ?? ''}'
              : '',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: isCompleted ? Colors.grey : const Color(0xFF6B7280),
          ),
        ),
        trailing: (item['type'] == 'measurement')
            ? const Icon(Icons.arrow_forward_ios_rounded)
            : Checkbox(
                value: isCompleted,
                onChanged: isPastOrToday
                    ? (bool? value) async {
                        if (value != null) {
                          int itemId = item['id'] as int;
                          if (itemId >= 200000) {
                            // Измерения (префикс 200000)
                            itemId -= 200000;
                            // Измерения не имеют статусов в reminder_statuses, пропускаем
                          } else if (itemId >= 100000) {
                            // Действия (префикс 100000)
                            itemId -= 100000;
                            await databaseService.updateActionStatus(
                                itemId, value);
                          } else {
                            // Напоминания
                            await databaseService.updateReminderStatus(
                                itemId, value, widget.date);
                          }
                          _loadChecklistData(); // Обновляем данные после изменения статуса
                        }
                      }
                    : null,
                shape: const CircleBorder(),
                activeColor: const Color(0xFF197FF2),
                checkColor: Colors.white,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMMM', 'ru_RU').format(widget.date);
    return Scaffold(
      appBar: AppBar(
        title: Text(formattedDate),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_reminders.isNotEmpty ||
                _actions.isNotEmpty ||
                _measurements.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    ..._reminders.map((reminder) {
                      final status = DatabaseService().getReminderStatusForDate(
                          reminder['id'] as int, widget.date);
                      return FutureBuilder<ReminderStatus?>(
                        future: status,
                        builder: (context, snapshot) {
                          return _buildChecklistItem(reminder,
                              snapshot.data == ReminderStatus.complete);
                        },
                      );
                    }).toList(),
                    ..._actions.map((action) {
                      final status = DatabaseService().getActionStatusForDate(
                          action['id'] as int, widget.date);
                      return FutureBuilder<ReminderStatus?>(
                        future: status,
                        builder: (context, snapshot) {
                          return _buildChecklistItem(
                              action, snapshot.data == ReminderStatus.complete);
                        },
                      );
                    }).toList(),
                    ..._measurements.map((measurement) {
                      // Измерения не имеют статуса в reminder_statuses, считаем не выполненным по умолчанию
                      return _buildChecklistItem(measurement, false);
                    }).toList(),
                  ],
                ),
              )
            else
              const Center(child: Text('Нет задач на эту дату')),
          ],
        ),
      ),
    );
  }
}
