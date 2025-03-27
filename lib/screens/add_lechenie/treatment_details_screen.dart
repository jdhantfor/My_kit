import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/barcodes_screen.dart';
import 'package:my_aptechka/screens/add_lechenie/calendar_widget.dart';
import 'package:my_aptechka/screens/table_time_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

class TreatmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final String userId;
  final Color color;

  const TreatmentDetailsScreen({
    super.key,
    required this.course,
    required this.userId,
    required this.color,
  });

  @override
  _TreatmentDetailsScreenState createState() => _TreatmentDetailsScreenState();
}

class _TreatmentDetailsScreenState extends State<TreatmentDetailsScreen> {
  int _selectedTab = 0;
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _measurements = [];
  List<Map<String, dynamic>> _actions = [];
  bool _isSettingsVisible = false;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _loadMeasurementsAndActions();
  }

  Future<void> _loadReminders() async {
    try {
      final databaseService = DatabaseService();
      final reminders = await databaseService.getRemindersByCourseId(
          widget.course['id'], widget.userId);
      setState(() {
        _reminders = reminders;
      });
    } catch (e) {
      print('Error loading reminders: $e');
    }
  }

  Future<void> _loadMeasurementsAndActions() async {
    try {
      final measurements = await DatabaseService.getMeasurements(widget.userId);
      final actions = await DatabaseService.getActions(widget.userId);
      setState(() {
        _measurements = measurements
            .where((m) => m['courseid'] == widget.course['id'])
            .toList();
        _actions =
            actions.where((a) => a['courseid'] == widget.course['id']).toList();
      });
    } catch (e) {
      print('Error loading measurements and actions: $e');
    }
  }

  Widget _buildReminderTile(Map<String, dynamic> item, String type) {
    final startDate = DateTime.parse(item['startDate']);
    final endDate =
        item['endDate'] != null ? DateTime.parse(item['endDate']) : null;
    final now = DateTime.now();
    final totalDays =
        endDate != null ? endDate.difference(startDate).inDays + 1 : null;
    final daysLeft =
        endDate != null ? endDate.difference(now).inDays + 1 : null;
    final isLifelong = item['isLifelong'] == 1;

    String remainingText = '';
    if (isLifelong) {
      remainingText = 'Бессрочно';
    } else if (endDate == null) {
      remainingText = 'Длительность не указана';
    } else if (daysLeft! <= 0) {
      remainingText = 'Курс завершён';
    } else {
      remainingText =
          'Осталось ${daysLeft > 0 ? daysLeft : 0} из ${totalDays ?? 0} дней';
    }

    Widget leadingIcon;
    switch (type) {
      case 'reminder':
        leadingIcon = SvgPicture.asset(
          'assets/priem_gray.svg',
          width: 28,
          height: 28,
          color: widget.color,
        );
        break;
      case 'measurement':
        leadingIcon = SvgPicture.asset(
          'assets/izmerenie_gray.svg',
          width: 28,
          height: 28,
          color: widget.color,
        );
        break;
      case 'action':
        leadingIcon = SvgPicture.asset(
          'assets/measss_gray.svg',
          width: 28,
          height: 28,
          color: widget.color,
        );
        break;
      default:
        leadingIcon = const SizedBox.shrink();
    }

    return Column(
      children: [
        ListTile(
          leading: leadingIcon,
          title: Text(
            item['name'],
            style: TextStyle(
              color: widget.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(remainingText),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TableTimeScreen(
                  name: item['name'],
                  unit: item['unit'] ?? '',
                  userId: widget.userId,
                  courseId: widget.course['id'],
                  reminderData: item,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCourseDates() {
    List<Map<String, dynamic>> allItems = [
      ..._reminders,
      ..._measurements,
      ..._actions
    ];
    if (allItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: Colors.black),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Не указано',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const Text(
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
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.black),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Бессрочно',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const Text(
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

    DateTime earliestStart = allItems
        .map((item) => DateTime.parse(item['startDate']))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime? latestEnd;
    if (allItems.where((item) => item['endDate'] != null).isNotEmpty) {
      latestEnd = allItems
          .where((item) => item['endDate'] != null)
          .map((item) => DateTime.parse(item['endDate']))
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final DateFormat dateFormat = DateFormat('d MMMM, EEE', 'ru_RU');
    final startDate = dateFormat.format(earliestStart);
    final endDate =
        latestEnd != null ? dateFormat.format(latestEnd) : 'Бессрочно';

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.black),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startDate,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const Text(
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
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Colors.black),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        endDate,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const Text(
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
    final allItems = [
      ..._reminders.map((item) => {'item': item, 'type': 'reminder'}),
      ..._measurements.map((item) => {'item': item, 'type': 'measurement'}),
      ..._actions.map((item) => {'item': item, 'type': 'action'}),
    ];

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        _buildCourseDates(),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              ...allItems.asMap().entries.map((entry) {
                final index = entry.key;
                final itemData = entry.value;
                final item = itemData['item'] as Map<String, dynamic>;
                final type = itemData['type'] as String;
                return Column(
                  children: [
                    _buildReminderTile(item, type),
                    if (index <
                        allItems.length -
                            1) // Разделитель только между элементами
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: const Divider(height: 1, color: Colors.grey),
                      ),
                  ],
                );
              }).toList(),
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
      ],
    );
  }

  Widget _buildStatisticsContent() {
    return CalendarWidget(
      courseId: widget.course['id'],
      userId: widget.userId,
    );
  }

  Future<void> _renameCourse() async {
    final TextEditingController controller =
        TextEditingController(text: widget.course['name']);
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
    if (newName != null &&
        newName.isNotEmpty &&
        newName != widget.course['name']) {
      await DatabaseService()
          .updateCourseName(widget.course['id'], newName, widget.userId);
      setState(() {
        widget.course['name'] = newName;
      });
    }
  }

  Future<void> _exportCourse() async {
    final pdf = pw.Document();

    final regularFontData =
        await rootBundle.load('fonts/commissioner/Commissioner-Regular.ttf');
    final regularTtf = pw.Font.ttf(regularFontData);

    final boldFontData =
        await rootBundle.load('fonts/commissioner/Commissioner-Bold.ttf');
    final boldTtf = pw.Font.ttf(boldFontData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Детали курса: ${widget.course['name']}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  font: boldTtf,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Начало курса: ${widget.course['startDate'] != null ? DateFormat('d MMMM yyyy').format(DateTime.parse(widget.course['startDate'])) : 'Не указано'}',
                style: pw.TextStyle(font: regularTtf),
              ),
              pw.Text(
                'Конец курса: ${widget.course['endDate'] != null ? DateFormat('d MMMM yyyy').format(DateTime.parse(widget.course['endDate'])) : 'Бессрочно'}',
                style: pw.TextStyle(font: regularTtf),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Напоминания:',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  font: boldTtf,
                ),
              ),
              pw.ListView.builder(
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('- ${reminder['name']}',
                          style: pw.TextStyle(font: regularTtf)),
                      pw.Text(
                        'Начало: ${DateFormat('d MMMM yyyy').format(DateTime.parse(reminder['startDate']))}',
                        style: pw.TextStyle(font: regularTtf),
                      ),
                      pw.Text(
                        'Конец: ${reminder['endDate'] != null ? DateFormat('d MMMM yyyy').format(DateTime.parse(reminder['endDate'])) : 'Бессрочно'}',
                        style: pw.TextStyle(font: regularTtf),
                      ),
                      pw.SizedBox(height: 10),
                    ],
                  );
                },
              ),
            ],
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
      Navigator.of(context).pop();
    }
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
                  case 'extend':
                    // TODO: Реализовать продление курса
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Функция продления в разработке')),
                    );
                    break;
                  case 'settings':
                    setState(() {
                      _isSettingsVisible = !_isSettingsVisible;
                    });
                    break;
                  case 'close_early':
                    // TODO: Реализовать досрочное закрытие
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Функция закрытия в разработке')),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: ListTile(
                    title: Text('Переименовать курс'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'export',
                  child: ListTile(
                    title: Text('Экспортировать курс'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'extend',
                  child: ListTile(
                    title: Text('Продлить курс'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(
                    title: Text('Настройки приёмности'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'close_early',
                  child: ListTile(
                    title: Text('Закрыть курс досрочно'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
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
                borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
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
}
