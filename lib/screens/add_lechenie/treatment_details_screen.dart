import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/barcodes_screen.dart';
import 'package:my_aptechka/screens/add_lechenie/calendar_widget.dart';
import 'package:my_aptechka/screens/table_time_screen.dart';

class TreatmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final String userId;
  final Color color; // Переданный цвет

  const TreatmentDetailsScreen({
    super.key,
    required this.course,
    required this.userId,
    required this.color, // Обязательный параметр
  });

  @override
  _TreatmentDetailsScreenState createState() => _TreatmentDetailsScreenState();
}

class _TreatmentDetailsScreenState extends State<TreatmentDetailsScreen> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _reminders = [];
  bool _isSettingsVisible = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final reminders = await DatabaseService.getRemindersByCourseId(
          widget.course['id'], widget.userId);
      setState(() {
        _reminders = reminders;
      });
    } catch (e) {
      print('Error loading reminders: $e');
    }
  }

  Widget _buildReminderTile(Map<String, dynamic> reminder) {
    final startDate = DateTime.parse(reminder['startDate']);
    final endDate = reminder['endDate'] != null
        ? DateTime.parse(reminder['endDate'])
        : null;
    final now = DateTime.now();
    final daysLeft = endDate != null ? endDate.difference(now).inDays : null;

    return Column(
      children: [
        ListTile(
          leading: Image.asset('assets/tabletk.png', width: 28, height: 28),
          title: Text(
            reminder['name'],
            style: TextStyle(
              color: widget.color, // Используем переданный цвет для текста
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Осталось ${daysLeft ?? 'Бессрочно'} дней из ${reminder['duration']}',
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TableTimeScreen(
                  name: reminder['name'],
                  unit: reminder['unit'] ?? '',
                  userId: widget.userId,
                  courseId: widget.course['id'],
                  reminderData: reminder,
                ),
              ),
            );
          },
        ),
        if (_reminders.last != reminder)
          const Divider(height: 1, color: Colors.grey),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.course['name']),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isSettingsVisible = !_isSettingsVisible;
                });
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      buildTabButton('Напоминание', 0),
                      buildTabButton('Статистика', 1),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _selectedTab == 0
                    ? _buildRemindersList()
                    : _buildStatisticsContent(),
              ),
            ],
          ),
          if (_isSettingsVisible)
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                'assets/lechenie_setting.png',
              ),
            ),
        ],
      ),
    );
  }

  Widget buildTabButton(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedTab == index ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedTab == index ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDates() {
    final startDate = widget.course['startDate'] != null
        ? DateFormat('d MMMM, EEE')
            .format(DateTime.parse(widget.course['startDate']))
        : 'Не указано';
    final endDate = widget.course['endDate'] != null
        ? DateFormat('d MMMM, EEE')
            .format(DateTime.parse(widget.course['endDate']))
        : 'Бессрочно';
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.black),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$startDate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Начало курса',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.flag, color: Colors.black),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$endDate',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Конец курса',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCourseDates(), // Добавляем блок с датами начала и конца курса
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                return _buildReminderTile(_reminders[index]);
              },
            ),
            ListTile(
              title: const Center(
                child: Text(
                  '+ Добавить',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BarcodesScreen(
                      userId: widget.userId,
                      courseId: widget.course['id'],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent() {
    return CalendarWidget(
      courseId: widget.course['id'],
      userId: widget.userId,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
