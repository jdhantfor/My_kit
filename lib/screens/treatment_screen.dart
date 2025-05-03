import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_lechenie/add_treatment_screen.dart';
import 'add_lechenie/action_or_habit_settings_screen.dart';
import 'add_lechenie/measurement_settings_screen.dart';
import 'table_time_screen.dart';
import 'database_service.dart';
import 'user_provider.dart';
import 'add_lechenie/treatment_details_screen.dart';
import '../styles.dart';

class TreatmentScreen extends StatefulWidget {
  const TreatmentScreen({super.key});

  @override
  _TreatmentScreenState createState() => _TreatmentScreenState();
}

class FamilyMember {
  final String id;
  final String? name;
  final String email;
  final String? surname;
  String? avatarUrl;

  FamilyMember({
    required this.id,
    this.name,
    required this.email,
    this.surname,
    this.avatarUrl,
  });

  String get displayName {
    if (name != null && name!.isNotEmpty) {
      if (surname != null && surname!.isNotEmpty) {
        return '$name $surname';
      }
      return name!;
    } else if (surname != null && surname!.isNotEmpty) {
      return surname!;
    }
    return email;
  }
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  List<Map<String, dynamic>> _treatmentCourses = [];
  List<Map<String, dynamic>> _unattachedReminders = [];
  List<Map<String, dynamic>> _unattachedActions = [];
  List<Map<String, dynamic>> _unattachedMeasurements = [];
  List<FamilyMember> familyMembers = [];
  FamilyMember? selectedMember;
  bool isFamilyListVisible = false;
  bool isLoading = true;
  String accessType = 'edit';

  @override
  void initState() {
    super.initState();
    // Слушаем изменения от UserProvider
    Provider.of<UserProvider>(context, listen: false).addListener(_onDataChanged);
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    // Удаляем слушателя при уничтожении виджета
    Provider.of<UserProvider>(context, listen: false).removeListener(_onDataChanged);
    super.dispose();
  }

  // Метод для обработки изменений данных
  void _onDataChanged() {
    if (mounted) {
      _loadTreatmentCourses();
      _loadUnattachedItems();
    }
  }

  Future<void> _loadFamilyMembers() async {
    setState(() => isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    final userEmail = userProvider.email;

    if (userId == null || userEmail == null) {
      print('Ошибка: ID или email пользователя не указан. userId: $userId, userEmail: $userEmail');
      setState(() => isLoading = false);
      return;
    }

    final currentUser = FamilyMember(
      id: userId,
      name: userProvider.name ?? 'Имя не указано',
      email: userEmail,
      avatarUrl: userProvider.avatarUrl,
    );

    const int maxRetries = 5;
    const Duration timeoutDuration = Duration(seconds: 30);
    int attempt = 0;
    final client = http.Client();

    try {
      while (attempt < maxRetries) {
        try {
          final request = http.Request(
            'GET',
            Uri.parse('http://62.113.37.96:5002/family_members?user_id=$userId'),
          )
            ..headers['Content-Type'] = 'application/json'
            ..headers['Connection'] = 'close';

          final streamedResponse = await client.send(request).timeout(timeoutDuration);
          final response = await http.Response.fromStream(streamedResponse);

          print('--- Отладка загрузки членов семьи ---');
          print('userId: $userId');
          print('URL запроса: http://62.113.37.96:5002/family_members?user_id=$userId');
          print('Статус ответа: ${response.statusCode}');
          print('Тело ответа: ${response.body}');

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            final List<dynamic> familyData = responseData['members'] ?? [];
            print('Данные членов семьи (familyData): $familyData');

            final List<FamilyMember> members = familyData.map((data) {
              return FamilyMember(
                id: data['user_id']?.toString() ?? '',
                name: data['name']?.toString(),
                email: data['email']?.toString() ?? '',
                surname: data['surname']?.toString(),
                avatarUrl: data['avatar_url']?.toString(),
              );
            }).toList();

            print('Список членов семьи после обработки (members): $members');

            setState(() {
              familyMembers = [currentUser, ...members];
              selectedMember = currentUser;
              isLoading = false;
            });
            _loadTreatmentCourses();
            _loadUnattachedItems();
            return;
          } else {
            print('Ошибка загрузки членов семьи: статус ${response.statusCode}');
            throw Exception('Ошибка сервера: ${response.statusCode}');
          }
        } catch (e) {
          attempt++;
          if (attempt == maxRetries) {
            print('Ошибка при загрузке членов семьи после $maxRetries попыток: $e');
            setState(() {
              familyMembers = [currentUser];
              selectedMember = currentUser;
              isLoading = false;
            });
            _loadTreatmentCourses();
            _loadUnattachedItems();
            return;
          }
          print('Попытка $attempt/$maxRetries: Ошибка при загрузке членов семьи: $e. Повтор через 3 секунды...');
          await Future.delayed(Duration(seconds: 3));
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> _loadTreatmentCourses() async {
    if (selectedMember == null) return;

    final userId = selectedMember!.id;
    final currentUserId = Provider.of<UserProvider>(context, listen: false).userId;

    if (userId == currentUserId) {
      // Для текущего пользователя используем локальную базу
      final courses = await DatabaseService.getTreatmentCoursesWithReminders(userId);
      List<Map<String, dynamic>> updatedCourses = [];
      for (var course in courses) {
        final courseId = course['id'];
        final measurements = await DatabaseService.getMeasurements(userId);
        final courseMeasurements = measurements.where((m) => m['courseid'] == courseId).toList();
        final actions = await DatabaseService.getActions(userId);
        final courseActions = actions.where((a) => a['courseid'] == courseId).toList();
        updatedCourses.add({
          ...course,
          'measurements': courseMeasurements,
          'actions': courseActions,
        });
      }
      setState(() {
        _treatmentCourses = updatedCourses;
        accessType = 'edit';
      });
    } else {
      // Для члена семьи запрашиваем данные с сервера
      try {
        final response = await http.get(
          Uri.parse('http://62.113.37.96:5002/api/sync?uid=$userId&requester_id=$currentUserId'),
        ).timeout(Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final serverData = data['data'] ?? {};
          final serverAccessType = data['access_type'] ?? 'view_only';

          final courses = (serverData['courses_table'] as List? ?? []).map((course) {
            final courseId = course['id'];
            final reminders = (serverData['reminders_table'] as List? ?? [])
                .where((r) => r['courseid'] == courseId)
                .toList()
                .cast<Map<String, dynamic>>();
            final measurements = (serverData['measurements_table'] as List? ?? [])
                .where((m) => m['courseid'] == courseId)
                .toList()
                .cast<Map<String, dynamic>>();
            final actions = (serverData['actions_table'] as List? ?? [])
                .where((a) => a['courseid'] == courseId)
                .toList()
                .cast<Map<String, dynamic>>();
            return {
              ...course as Map<String, dynamic>,
              'reminders': reminders,
              'measurements': measurements,
              'actions': actions,
            };
          }).toList();

          setState(() {
            _treatmentCourses = courses.cast<Map<String, dynamic>>();
            accessType = serverAccessType;
          });
        } else {
          print('Ошибка загрузки курсов семьи: ${response.statusCode}');
          setState(() {
            _treatmentCourses = [];
            accessType = 'view_only';
          });
        }
      } catch (e) {
        print('Ошибка при запросе курсов семьи: $e');
        setState(() {
          _treatmentCourses = [];
          accessType = 'view_only';
        });
      }
    }
  }

  Future<void> _loadUnattachedItems() async {
    if (selectedMember == null) return;

    final userId = selectedMember!.id;
    final currentUserId = Provider.of<UserProvider>(context, listen: false).userId;

    if (userId == currentUserId) {
      // Для текущего пользователя используем локальную базу
      final unattachedReminders = await DatabaseService.getUnattachedReminders(userId);
      final unattachedActions = await DatabaseService.getUnattachedActions(userId);
      final unattachedMeasurements = await DatabaseService.getUnattachedMeasurements(userId);
      setState(() {
        _unattachedReminders = unattachedReminders;
        _unattachedActions = unattachedActions;
        _unattachedMeasurements = unattachedMeasurements;
        accessType = 'edit';
      });
    } else {
      // Для члена семьи запрашиваем данные с сервера
      try {
        final response = await http.get(
          Uri.parse('http://62.113.37.96:5002/api/sync?uid=$userId&requester_id=$currentUserId'),
        ).timeout(Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final serverData = data['data'] ?? {};
          final serverAccessType = data['access_type'] ?? 'view_only';

          final unattachedReminders = (serverData['reminders_table'] as List? ?? [])
              .where((r) => r['courseid'] == null || r['courseid'] == -1)
              .toList()
              .cast<Map<String, dynamic>>();
          final unattachedActions = (serverData['actions_table'] as List? ?? [])
              .where((a) => a['courseid'] == null || a['courseid'] == -1)
              .toList()
              .cast<Map<String, dynamic>>();
          final unattachedMeasurements = (serverData['measurements_table'] as List? ?? [])
              .where((m) => m['courseid'] == null || m['courseid'] == -1)
              .toList()
              .cast<Map<String, dynamic>>();

          setState(() {
            _unattachedReminders = unattachedReminders;
            _unattachedActions = unattachedActions;
            _unattachedMeasurements = unattachedMeasurements;
            accessType = serverAccessType;
          });
        } else {
          print('Ошибка загрузки unattached данных семьи: ${response.statusCode}');
          setState(() {
            _unattachedReminders = [];
            _unattachedActions = [];
            _unattachedMeasurements = [];
            accessType = 'view_only';
          });
        }
      } catch (e) {
        print('Ошибка при запросе unattached данных семьи: $e');
        setState(() {
          _unattachedReminders = [];
          _unattachedActions = [];
          _unattachedMeasurements = [];
          accessType = 'view_only';
        });
      }
    }
  }

  void _navigateToAddTreatmentScreen() {
    if (selectedMember == null || accessType != 'edit') return;

    final userId = selectedMember!.id;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTreatmentScreen(userId: userId),
      ),
    ).then((_) {
      _loadTreatmentCourses();
      _loadUnattachedItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasCourses = _treatmentCourses.isNotEmpty;
    bool hasUnattachedItems = _unattachedReminders.isNotEmpty ||
        _unattachedActions.isNotEmpty ||
        _unattachedMeasurements.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () {
            setState(() {
              isFamilyListVisible = !isFamilyListVisible;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Курсы лечения',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(width: 8),
              if (familyMembers.length > 1)
                SvgPicture.asset(
                  isFamilyListVisible ? 'assets/arrow_down.svg' : 'assets/arrow_down.svg',
                  width: 24,
                  height: 24,
                ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isFamilyListVisible && familyMembers.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: familyMembers.map((member) {
                          return ListTile(
                            title: Text(
                              member.displayName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF0B102B),
                                  ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedMember = member;
                                isFamilyListVisible = false;
                              });
                              _loadTreatmentCourses();
                              _loadUnattachedItems();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                Expanded(
                  child: !hasCourses && !hasUnattachedItems
                      ? _buildEmptyList()
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasCourses) _buildCoursesList(),
                              if (hasUnattachedItems) _buildUnattachedItems(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: accessType == 'edit'
          ? FloatingActionButton(
              onPressed: _navigateToAddTreatmentScreen,
              backgroundColor: AppColors.primaryBlue,
              shape: const CircleBorder(),
              elevation: 0,
              heroTag: 'uniqueTagForTreatmentScreen',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCoursesList() {
    final colors = [
      const Color.fromRGBO(22, 178, 217, 0.2),
      const Color.fromRGBO(86, 199, 0, 0.2),
      const Color.fromRGBO(159, 25, 242, 0.2),
      const Color.fromRGBO(242, 25, 141, 0.2),
      const Color.fromRGBO(242, 153, 0, 0.2),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_treatmentCourses.isNotEmpty) ...[
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

              // Группируем напоминания по названию
              final Map<String, List<Map<String, dynamic>>> groupedReminders = {};
              if (reminders != null && reminders.isNotEmpty) {
                for (var reminder in reminders) {
                  final name = reminder['name'] as String;
                  if (!groupedReminders.containsKey(name)) {
                    groupedReminders[name] = [];
                  }
                  groupedReminders[name]!.add(reminder);
                }
              }

              // Преобразуем в список уникальных записей
              final List<Map<String, dynamic>> uniqueReminders = groupedReminders.entries.map((entry) {
                final firstReminder = entry.value.first;
                return firstReminder;
              }).toList();

              DateTime? minStartDate;
              DateTime? maxEndDate;
              bool isLifelong = false;

              if (reminders != null && reminders.isNotEmpty) {
                for (final reminder in reminders) {
                  final start = DateTime.parse(reminder['startDate']);
                  if (minStartDate == null || start.isBefore(minStartDate)) {
                    minStartDate = start;
                  }
                  if (reminder['isLifelong'] == 1) {
                    isLifelong = true;
                  } else if (reminder['endDate'] != null) {
                    final end = DateTime.parse(reminder['endDate']);
                    if (maxEndDate == null || end.isAfter(maxEndDate)) {
                      maxEndDate = end;
                    }
                  }
                }
              }

              if (measurements != null && measurements.isNotEmpty) {
                for (final measurement in measurements) {
                  final start = DateTime.parse(measurement['startDate']);
                  if (minStartDate == null || start.isBefore(minStartDate)) {
                    minStartDate = start;
                  }
                  if (measurement['isLifelong'] == 1) {
                    isLifelong = true;
                  } else if (measurement['endDate'] != null) {
                    final end = DateTime.parse(measurement['endDate']);
                    if (maxEndDate == null || end.isAfter(maxEndDate)) {
                      maxEndDate = end;
                    }
                  }
                }
              }

              if (actions != null && actions.isNotEmpty) {
                for (final action in actions) {
                  final start = DateTime.parse(action['startDate']);
                  if (minStartDate == null || start.isBefore(minStartDate)) {
                    minStartDate = start;
                  }
                  if (action['isLifelong'] == 1) {
                    isLifelong = true;
                  } else if (action['endDate'] != null) {
                    final end = DateTime.parse(action['endDate']);
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
                final totalDays = maxEndDate.difference(minStartDate).inDays + 1;
                final daysLeft = maxEndDate.difference(DateTime.now()).inDays + 1;
                remainingDaysText = 'Осталось $daysLeft из $totalDays дней';
                periodText = '${_formatDateVerbose(minStartDate)} – ${_formatDateVerbose(maxEndDate)}';
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
                        userId: selectedMember!.id,
                        color: color,
                      ),
                    ),
                  ).then((_) {
                    _loadTreatmentCourses();
                    _loadUnattachedItems();
                  });
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
                                course['name'] != null && (course['name'] as String).length > 25
                                    ? '${(course['name'] as String).substring(0, 25)}...'
                                    : course['name'] ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Commissioner',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0B102B),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
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
                                      if (uniqueReminders.isNotEmpty)
                                        for (final reminder in uniqueReminders)
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                                  color: const Color(0xFF0B102B),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  reminder['name'].length > 10
                                                      ? '${reminder['name'].substring(0, 10)}...'
                                                      : reminder['name'],
                                                  style: const TextStyle(
                                                    fontFamily: 'Commissioner',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF0B102B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      if (measurements != null && measurements.isNotEmpty)
                                        for (final measurement in measurements)
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/izmerenie_gray.svg',
                                                  width: 16,
                                                  height: 16,
                                                  color: const Color(0xFF0B102B),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  measurement['name'].length > 10
                                                      ? '${measurement['name'].substring(0, 10)}...'
                                                      : measurement['name'],
                                                  style: const TextStyle(
                                                    fontFamily: 'Commissioner',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF0B102B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      if (actions != null && actions.isNotEmpty)
                                        for (final action in actions)
                                          Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/measss_gray.svg',
                                                  width: 16,
                                                  height: 16,
                                                  color: const Color(0xFF0B102B),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  action['name'].length > 10
                                                      ? '${action['name'].substring(0, 10)}...'
                                                      : action['name'],
                                                  style: const TextStyle(
                                                    fontFamily: 'Commissioner',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF0B102B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      if ((uniqueReminders.isEmpty) &&
                                          (measurements == null || measurements.isEmpty) &&
                                          (actions == null || actions.isEmpty))
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Text(
                                            'Напоминания не добавлены',
                                            style: TextStyle(
                                              fontFamily: 'Commissioner',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
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
                                        colors: [Colors.transparent, Colors.transparent],
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
                                  fontFamily: 'Commissioner',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              Text(
                                periodText,
                                style: const TextStyle(
                                  fontFamily: 'Commissioner',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6B7280),
                                ),
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
        ],
      ],
    );
  }

  Widget _buildUnattachedItems() {
    if (_unattachedReminders.isEmpty && _unattachedActions.isEmpty && _unattachedMeasurements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),
          ..._unattachedReminders.map((item) => _buildUnattachedItem(item, 'assets/priem_gray.svg')),
          ..._unattachedActions.map((item) => _buildUnattachedItem(item, 'assets/measss_gray.svg')),
          ..._unattachedMeasurements.map((item) => _buildUnattachedItem(item, 'assets/izmerenie_gray.svg')),
        ],
      ),
    );
  }

  Widget _buildUnattachedItem(Map<String, dynamic> item, String iconPath) {
    print('Текущий item: $item');

    bool isMeasurement = iconPath == 'assets/izmerenie_gray.svg';
    bool isAction = iconPath == 'assets/measss_gray.svg';
    bool isReminder = iconPath == 'assets/priem_gray.svg';

    final userId = selectedMember?.id;

    void _navigateToEditScreen() {
      if (accessType != 'edit' || userId == null) return;

      print('Нажатие на стрелку для элемента: ${item['name'] ?? 'Без названия'}');
      print('userId: $userId');

      if (isMeasurement) {
        print('Попытка перехода на MeasurementSettingsScreen для: ${item['name']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeasurementSettingsScreen(
              userId: userId,
              courseId: item['courseid'] ?? -1,
              measurementType: item['name'] ?? 'Измерение',
              initialData: item,
            ),
          ),
        ).then((_) {
          print('Возврат из MeasurementSettingsScreen, обновляем список');
          _loadUnattachedItems();
        });
      } else if (isAction) {
        print('Попытка перехода на ActionOrHabitSettingsScreen для: ${item['name']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActionOrHabitSettingsScreen(
              userId: userId,
              courseId: item['courseid'] ?? -1,
              actionType: item['name'] ?? 'Действие',
              customName: item['name'],
              initialData: item,
            ),
          ),
        ).then((_) {
          print('Возврат из ActionOrHabitSettingsScreen, обновляем список');
          _loadUnattachedItems();
        });
      } else if (isReminder) {
        print('Попытка перехода на TableTimeScreen для: ${item['name']}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableTimeScreen(
              userId: userId,
              courseId: item['courseid'] ?? -1,
              name: item['name'] ?? 'Напоминание',
              unit: item['unit'] ?? '',
              reminderData: item,
              fromUnattachedReminder: true,
            ),
          ),
        ).then((_) {
          _loadUnattachedItems();
        });
      }
    }

    return Padding(
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
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] != null && (item['name'] as String).length > 25
                            ? '${(item['name'] as String).substring(0, 25)}...'
                            : item['name'] ?? 'Без названия',
                        style: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B102B),
                        ),
                      ),
                      Text(
                        _getItemSubtitle(item),
                        style: const TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (accessType == 'edit')
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _navigateToEditScreen,
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
            ],
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
          Image.asset('assets/tablet.png',
          height: 180,
          width: 180,),
          const SizedBox(height: 16),
          Text(
            'Пока что нет курсов лечения',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: const Color(0xFF0B102B),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Курс может содержать напоминания\nо приёмах препаратов, процедурах,\nдействиях или что-то одно',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
            textAlign: TextAlign.center,
          ),
          if (accessType == 'edit') ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToAddTreatmentScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                minimumSize: const Size(0, 48),
              ),
              child: Text(
                'Добавить',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
              ),
            ),
          ],
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