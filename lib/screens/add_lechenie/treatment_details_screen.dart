import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/barcodes_screen.dart';
import 'package:my_aptechka/screens/add_lechenie/calendar_widget.dart';
import 'package:my_aptechka/screens/table_time_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
      // Используем синглтон-экземпляр DatabaseService
      final databaseService = DatabaseService(); // Получаем экземпляр синглтона
      final reminders = await databaseService.getRemindersByCourseId(
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
    final daysLeft = endDate?.difference(now).inDays;

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
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz, color: Colors.black),
        onSelected: (String result) {
          switch (result) {
            case 'rename':
              _renameCourse();
              break;
            case 'export':
              _exportCourse();
              break;
            case 'delete':
              _deleteCourse();
              break;
            default:
              // Для остальных пунктов ничего не делаем
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Клик по: $result')),
              );
              break;
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'rename',
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Переименовать курс'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'export',
            child: ListTile(
              leading: Icon(Icons.file_download, color: Colors.grey),
              title: Text('Экспортировать курс'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'extend',
            child: ListTile(
              leading: Icon(Icons.add_circle, color: Colors.blue),
              title: Text('Продлить курс'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'settings',
            child: ListTile(
              leading: Icon(Icons.settings, color: Colors.grey),
              title: Text('Настройки приёмности'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'close_early',
            child: ListTile(
              leading: Icon(Icons.close, color: Colors.red),
              title: Text('Закрыть курс досрочно'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Удалить курс'),
            ),
          ),
        ],
      ),
    ),
  ],
),
      body: Column(
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
                        startDate,
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
                        endDate,
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
  Future<void> _renameCourse() async {
  final TextEditingController controller = TextEditingController();
  final newName = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Переименовать курс'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Новое название'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Сохранить'),
          ),
        ],
      );
    },
  );
  if (newName != null && newName.isNotEmpty) {
    await DatabaseService().updateCourseName(widget.course['id'], newName, widget.userId);
    setState(() {
      widget.course['name'] = newName;
    });
  }
}
Future<void> _exportCourse() async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Text('Детали курса: ${widget.course['name']}'),
        );
      },
    ),
  );
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
Future<void> _deleteCourse() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Удалить курс'),
        content: const Text('Вы уверены, что хотите удалить этот курс?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      );
    },
  );
  if (confirm == true) {
    await DatabaseService().deleteCourse(widget.course['id'], widget.userId);
    Navigator.of(context).pop(); // Возвращаемся на предыдущий экран
  }
}
}
