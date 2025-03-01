import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/add_lechenie/add_treatment_screen.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:provider/provider.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'add_lechenie/treatment_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TreatmentScreen extends StatefulWidget {
  const TreatmentScreen({super.key});

  @override
  _TreatmentScreenState createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  List<Map<String, dynamic>> _treatmentCourses = [];
  List<Map<String, dynamic>> _unattachedReminders = [];
  List<Map<String, dynamic>> _unattachedActions = [];
  List<Map<String, dynamic>> _unattachedMeasurements = [];

  @override
  void initState() {
    super.initState();
    _loadTreatmentCourses();
    _loadUnattachedItems(); // Добавляем загрузку непривязанных элементов
  }

  Future<void> _loadTreatmentCourses() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    if (userId != null) {
      final courses =
          await DatabaseService.getTreatmentCoursesWithReminders(userId);
      setState(() {
        _treatmentCourses = courses;
      });
    } else {
      print('User is not logged in');
    }
  }

  Future<void> _loadUnattachedItems() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final userId = userProvider.userId;
  if (userId != null) {
    final unattachedReminders = await DatabaseService.getUnattachedReminders(userId);
    final unattachedActions = await DatabaseService.getUnattachedActions(userId);
    final unattachedMeasurements = await DatabaseService.getUnattachedMeasurements(userId);
    setState(() {
      _unattachedReminders = unattachedReminders;
      _unattachedActions = unattachedActions;
      _unattachedMeasurements = unattachedMeasurements;
    });
  } else {
    print('User is not logged in');
  }
}

  void _navigateToAddTreatmentScreen() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTreatmentScreen(userId: userId),
        ),
      ).then((_) => _loadTreatmentCourses());
    } else {
      print('User is not logged in');
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Курсы лечения'),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () {
            // Логика открытия настроек
          },
        ),
      ],
    ),
    body: _treatmentCourses.isEmpty ? _buildEmptyList() : _buildTreatmentList(),
    floatingActionButton: FloatingActionButton(
      onPressed: _navigateToAddTreatmentScreen,
      backgroundColor: const Color(0xFF197FF2),
      shape: const CircleBorder(),
      heroTag: 'uniqueTagForTreatmentScreen',
      child: const Icon(Icons.add, color: Colors.white),
    ),
  );
}
Widget _buildUnattachedItems() {
  // Если все списки пустые, возвращаем пустой виджет
  if (_unattachedReminders.isEmpty && _unattachedActions.isEmpty && _unattachedMeasurements.isEmpty) {
    return SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Непривязанные элементы', // Можно изменить на "Завершённые курсы", как в дизайне
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        // Комбинируем все элементы в один список
        ..._unattachedReminders.map((item) => _buildUnattachedItem(item, 'assets/priem_gray.svg')),
        ..._unattachedActions.map((item) => _buildUnattachedItem(item, 'assets/measss_gray.svg')),
        ..._unattachedMeasurements.map((item) => _buildUnattachedItem(item, 'assets/izmerenie_blue.svg')),
      ],
    ),
  );
}

Widget _buildUnattachedItem(Map<String, dynamic> item, String iconPath) {
  return GestureDetector(
    onTap: () {
      // Можно добавить переход на экран деталей, если нужно
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SvgPicture.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: iconPath.contains('blue') ? Colors.blue : Colors.grey,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Без названия',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getItemSubtitle(item),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    ),
  );
}

String _getItemSubtitle(Map<String, dynamic> item) {
  if (item.containsKey('dosage') && item['dosage'] != null) {
    return 'Дозировка: ${item['dosage']} ${item['unit'] ?? ''}';
  } else if (item.containsKey('mealTime') && item['mealTime'] != null) {
    return 'Время приема: ${item['mealTime']}';
  } else if (item.containsKey('time') && item['time'] != null) {
    return 'Время измерения: ${item['time']}';
  }
  return 'Нет данных';
}
  Widget _buildEmptyList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/tablet.png',
            width: 300,
            height: 300,
          ),
          const SizedBox(height: 20),
          const Text(
            'Пока что нет курсов лечения',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Курс может содержать напоминания\nо приёмах препаратов, процедурах,\nдействиях или что-то одно',
            style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _navigateToAddTreatmentScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF197FF2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

 Widget _buildTreatmentList() {
  final colors = [
    const Color.fromRGBO(22, 178, 217, 0.2),
    const Color.fromRGBO(86, 199, 0, 0.2),
    const Color.fromRGBO(159, 25, 242, 0.2),
    const Color.fromRGBO(242, 25, 141, 0.2),
    const Color.fromRGBO(242, 153, 0, 0.2),
  ];

  return SingleChildScrollView(
    child: Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _treatmentCourses.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final course = _treatmentCourses[index];
            final colorIndex = index % colors.length;
            final color = colors[colorIndex];
            final reminders = course['reminders'] as List?;
            DateTime? startDate;
            DateTime? endDate;
            String remainingDaysText = '';
            String periodText = '';
            if (reminders != null && reminders.isNotEmpty) {
              final firstReminder = reminders.first;
              startDate = DateTime.parse(firstReminder['startDate']);
              final isLifelong = firstReminder['isLifelong'] == 1;
              final duration = firstReminder['duration'] as num?;
              final durationUnit = firstReminder['durationUnit'] as String?;
              if (!isLifelong && duration != null && durationUnit != null) {
                if (durationUnit == 'дней') {
                  endDate = startDate.add(Duration(days: duration.toInt()));
                } else if (durationUnit == 'месяцев') {
                  endDate = DateTime(startDate.year + (duration.toInt() ~/ 12),
                      startDate.month + duration.toInt() % 12, startDate.day);
                }
              }
              if (isLifelong) {
                remainingDaysText = 'Бессрочный курс';
                periodText = 'С ${_formatDateVerbose(startDate)}';
              } else if (endDate != null && duration != null && durationUnit != null) {
                remainingDaysText =
                    'Осталось ${endDate.difference(DateTime.now()).inDays} из ${duration.toInt()} ${_getDurationUnitText(durationUnit)}';
                periodText =
                    '${_formatDateVerbose(startDate)} – ${_formatDateVerbose(endDate)}';
              } else {
                remainingDaysText = 'Информация о длительности отсутствует';
                periodText = 'С ${_formatDateVerbose(startDate)}';
              }
            } else {
              remainingDaysText = 'Нет напоминаний';
              periodText = '';
            }
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreatmentDetailsScreen(
                      course: course,
                      userId: Provider.of<UserProvider>(context, listen: false).userId!,
                      color: color,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              course['name'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (reminders != null && reminders.isNotEmpty)
                              for (final reminder in reminders)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        'assets/priem_gray.svg',
                                        width: 16,
                                        height: 16,
                                        color: Color(color.value | 0xFF000000),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        reminder['name'].length > 10
                                            ? '${reminder['name'].substring(0, 10)}...'
                                            : reminder['name'],
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Color(color.value | 0xFF000000)),
                                      ),
                                    ],
                                  ),
                                )
                            else
                              const Text('Напоминания не добавлены'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              remainingDaysText,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              periodText,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        _buildUnattachedItems(), // Добавляем секцию непривязанных элементов
      ],
    ),
  );
}

  String _formatDateVerbose(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final monthName = _getMonthName(date.month);
    return '$day $monthName';
  }

  String _getMonthName(int month) {
    const monthNames = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return monthNames[month - 1];
  }

  String _getDurationUnitText(String unit) {
    switch (unit) {
      case 'дней':
        return 'дней';
      case 'месяцев':
        return 'месяцев';
      default:
        return unit;
    }
  }
  
}
