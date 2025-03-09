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
    _loadUnattachedItems();
  }

  Future<void> _loadTreatmentCourses() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    if (userId != null) {
      final courses =
          await DatabaseService.getTreatmentCoursesWithReminders(userId);
      List<Map<String, dynamic>> updatedCourses = [];
      for (var course in courses) {
        final courseId = course['id'];
        final measurements = await DatabaseService.getMeasurements(userId);
        final courseMeasurements =
            measurements.where((m) => m['courseid'] == courseId).toList();
        final actions = await DatabaseService.getActions(userId);
        final courseActions =
            actions.where((a) => a['courseid'] == courseId).toList();
        updatedCourses.add({
          ...course,
          'measurements': courseMeasurements,
          'actions': courseActions,
        });
      }
      setState(() {
        _treatmentCourses = updatedCourses;
      });
    } else {
      print('User is not logged in');
    }
  }

  Future<void> _loadUnattachedItems() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    if (userId != null) {
      final unattachedReminders =
          await DatabaseService.getUnattachedReminders(userId);
      final unattachedActions =
          await DatabaseService.getUnattachedActions(userId);
      final unattachedMeasurements =
          await DatabaseService.getUnattachedMeasurements(userId);
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
      body:
          _treatmentCourses.isEmpty ? _buildEmptyList() : _buildTreatmentList(),
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
    if (_unattachedReminders.isEmpty &&
        _unattachedActions.isEmpty &&
        _unattachedMeasurements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Непривязанные элементы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._unattachedReminders.map(
              (item) => _buildUnattachedItem(item, 'assets/priem_gray.svg')),
          ..._unattachedActions.map(
              (item) => _buildUnattachedItem(item, 'assets/measss_gray.svg')),
          ..._unattachedMeasurements.map((item) =>
              _buildUnattachedItem(item, 'assets/izmerenie_gray.svg')),
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
                offset: const Offset(0, 1),
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
                      color:
                          iconPath.contains('blue') ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Без названия',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getItemSubtitle(item),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
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
              fontWeight: FontWeight.w500,
            ),
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
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _treatmentCourses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final course = _treatmentCourses[index];
              final colorIndex = index % colors.length;
              final color = colors[colorIndex];
              final reminders = course['reminders'] as List?;
              final measurements = course['measurements'] as List?;
              final actions = course['actions'] as List?;

              // Находим минимальную startDate и максимальную endDate
              DateTime? minStartDate;
              DateTime? maxEndDate;
              bool isLifelong = false;

              // Проверяем напоминания
              if (reminders != null && reminders.isNotEmpty) {
                for (final reminder in reminders) {
                  final start = DateTime.parse(reminder['startDate']);
                  final end = DateTime.parse(
                      reminder['endDate']); // Используем endDate напрямую
                  if (minStartDate == null || start.isBefore(minStartDate)) {
                    minStartDate = start;
                  }
                  if (reminder['isLifelong'] == 1) {
                    isLifelong = true;
                  } else {
                    if (maxEndDate == null || end.isAfter(maxEndDate)) {
                      maxEndDate = end;
                    }
                  }
                }
              }

              // Проверяем измерения
              if (measurements != null && measurements.isNotEmpty) {
                for (final measurement in measurements) {
                  final start = DateTime.parse(measurement['startDate']);
                  final end = DateTime.parse(
                      measurement['endDate']); // Используем endDate напрямую
                  if (minStartDate == null || start.isBefore(minStartDate)) {
                    minStartDate = start;
                  }
                  if (measurement['isLifelong'] == 1) {
                    isLifelong = true;
                  } else {
                    if (maxEndDate == null || end.isAfter(maxEndDate)) {
                      maxEndDate = end;
                    }
                  }
                }
              }

              // Проверяем действия
              if (actions != null && actions.isNotEmpty) {
                for (final action in actions) {
                  final start = DateTime.parse(action['startDate']);
                  final end = DateTime.parse(
                      action['endDate']); // Используем endDate напрямую
                  if (minStartDate == null || start.isBefore(minStartDate)) {
                    minStartDate = start;
                  }
                  if (action['isLifelong'] == 1) {
                    isLifelong = true;
                  } else {
                    if (maxEndDate == null || end.isAfter(maxEndDate)) {
                      maxEndDate = end;
                    }
                  }
                }
              }

              String remainingDaysText = '';
              String periodText = '';

              if (minStartDate == null) {
                remainingDaysText = 'Нет данных';
                periodText = '';
              } else if (isLifelong) {
                remainingDaysText = 'Бессрочный курс';
                periodText = 'С ${_formatDateVerbose(minStartDate)}';
              } else if (maxEndDate != null) {
                final totalDays =
                    maxEndDate.difference(minStartDate).inDays + 1;
                final daysLeft = maxEndDate.difference(DateTime.now()).inDays +
                    1; // Добавляем +1, чтобы включить последний день
                remainingDaysText = 'Осталось $daysLeft из $totalDays дней';
                periodText =
                    '${_formatDateVerbose(minStartDate)} – ${_formatDateVerbose(maxEndDate)}';
              } else {
                remainingDaysText = 'Информация о длительности отсутствует';
                periodText = 'С ${_formatDateVerbose(minStartDate)}';
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreatmentDetailsScreen(
                        course: course,
                        userId:
                            Provider.of<UserProvider>(context, listen: false)
                                .userId!,
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
                          SizedBox(
                            height: 40,
                            child: Stack(
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      if (reminders != null &&
                                          reminders.isNotEmpty)
                                        for (final reminder in reminders)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/priem_gray.svg',
                                                  width: 16,
                                                  height: 16,
                                                  color: Color(
                                                      color.value | 0xFF000000),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  reminder['name'].length > 10
                                                      ? '${reminder['name'].substring(0, 10)}...'
                                                      : reminder['name'],
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(color.value |
                                                          0xFF000000)),
                                                ),
                                              ],
                                            ),
                                          ),
                                      if (measurements != null &&
                                          measurements.isNotEmpty)
                                        for (final measurement in measurements)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/izmerenie_gray.svg',
                                                  width: 16,
                                                  height: 16,
                                                  color: Color(
                                                      color.value | 0xFF000000),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  measurement['name'].length >
                                                          10
                                                      ? '${measurement['name'].substring(0, 10)}...'
                                                      : measurement['name'],
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(color.value |
                                                          0xFF000000)),
                                                ),
                                              ],
                                            ),
                                          ),
                                      if (actions != null && actions.isNotEmpty)
                                        for (final action in actions)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/measss_gray.svg',
                                                  width: 16,
                                                  height: 16,
                                                  color: Color(
                                                      color.value | 0xFF000000),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  action['name'].length > 10
                                                      ? '${action['name'].substring(0, 10)}...'
                                                      : action['name'],
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(color.value |
                                                          0xFF000000)),
                                                ),
                                              ],
                                            ),
                                          ),
                                      if ((reminders == null ||
                                              reminders.isEmpty) &&
                                          (measurements == null ||
                                              measurements.isEmpty) &&
                                          (actions == null || actions.isEmpty))
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child:
                                              Text('Напоминания не добавлены'),
                                        ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 40,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.transparent
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                remainingDaysText,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                periodText,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
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
          _buildUnattachedItems(),
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
}
