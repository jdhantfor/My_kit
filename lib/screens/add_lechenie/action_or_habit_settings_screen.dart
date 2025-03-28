import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'action_or_habit_schedule_screen.dart';
import 'action_schedule_box.dart';
import 'custom_quantity_input.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/home_screen.dart'; // Импорт HomeScreen
import 'course_selection_box.dart';

class ActionOrHabitSettingsScreen extends StatefulWidget {
  final String userId;
  final int courseId;
  final String actionType;
  final String? customName;

  const ActionOrHabitSettingsScreen({
    super.key,
    required this.userId,
    required this.courseId,
    required this.actionType,
    this.customName,
  });

  @override
  ActionOrHabitSettingsScreenState createState() =>
      ActionOrHabitSettingsScreenState();
}

class ActionOrHabitSettingsScreenState
    extends State<ActionOrHabitSettingsScreen> {
  bool _isLifelong = true;
  DateTime _startDate = DateTime.now();
  int _durationValue = 30;
  String _durationUnit = 'дней';
  double _quantity = 1.0;
  String _selectedScheduleType = 'daily';
  String _selectedMealTime = 'Выбор';
  String _selectedNotification = 'Выбор';
  int? _selectedCourseId;

  bool _isStartDateChanged = false; // Флаг для отслеживания изменения даты
  bool _showDurationPickerInside = false; // Флаг для показа выбора длительности

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
  }

  void _addActionOrHabit() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите курс лечения')),
      );
      return;
    }

    DateTime? endDate;
    if (!_isLifelong) {
      if (_durationUnit == 'дней') {
        endDate = _startDate.add(Duration(days: _durationValue - 1));
      } else if (_durationUnit == 'недель') {
        endDate = _startDate.add(Duration(days: _durationValue * 7 - 1));
      }
    }

    final actionData = {
      'name': widget.customName ?? widget.actionType,
      'isLifelong': _isLifelong ? 1 : 0,
      'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
      'endDate':
          endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
      'courseid': _selectedCourseId,
      'user_id': widget.userId,
      'quantity': _quantity,
      'schedule_type': _selectedScheduleType,
      'mealTime': _selectedMealTime,
      'notification': _selectedNotification,
    };

    try {
      final databaseService = DatabaseService();
      await databaseService.addActionOrHabit(actionData, widget.userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Действие/привычка добавлена')),
      );

      // Переход на HomeScreen с очисткой стека
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _showDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        _isStartDateChanged = true;
      });
    }
  }

  void _toggleDurationPicker() {
    setState(() {
      _showDurationPickerInside = !_showDurationPickerInside;
    });
  }

  void _showDurationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Длительность выполнения',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 194, 193, 193),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 1,
                          child: ListWheelScrollView(
                            itemExtent: 50,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _durationValue = index + 1;
                              });
                            },
                            children: List.generate(7, (index) {
                              return Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: Color.fromARGB(255, 48, 48, 48),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: ListWheelScrollView(
                            itemExtent: 50,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _durationUnit = index == 0 ? 'дней' : 'недель';
                              });
                            },
                            children: ['дней', 'недель'].map((unit) {
                              return Center(
                                child: Text(
                                  unit,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    color: Color.fromARGB(255, 37, 37, 37),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      if (_durationUnit == 'недель') {
                        _durationValue *= 7;
                        _durationUnit = 'дней';
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF197FF2),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        title: Text(widget.customName ?? widget.actionType),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  'Длительность действия/привычки',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Бессрочно',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0B102B),
                              ),
                            ),
                            Transform.scale(
                              scale:
                                  0.8, // Уменьшаем размер как в TableTimeScreen
                              child: Switch(
                                value: _isLifelong,
                                onChanged: (value) {
                                  setState(() {
                                    _isLifelong = value;
                                    _toggleDurationPicker();
                                  });
                                },
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFF197FF2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Начало выполнения',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0B102B),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _showDatePicker(context);
                              },
                              child: Row(
                                children: [
                                  Text(
                                    _isStartDateChanged
                                        ? DateFormat('dd.MM.yyyy')
                                            .format(_startDate)
                                        : 'Сегодня',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF197FF2),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF197FF2),
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showDurationPickerInside && !_isLifelong)
                        Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Divider(
                                  color: Color(0xFFE0E0E0), thickness: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Срок выполнения',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF0B102B),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _showDurationPicker(context);
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          '$_durationValue $_durationUnit',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF197FF2),
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Color(0xFF197FF2),
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Количество',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              CustomQuantityInput(
                quantity: _quantity,
                onQuantityChanged: (value) {
                  setState(() {
                    _quantity = value;
                  });
                },
              ),
              const SizedBox(height: 4.0),
              ActionScheduleBox(
                onNavigateToScheduleScreen: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActionOrHabitScheduleScreen(
                        name: widget.customName ?? widget.actionType,
                        unit: 'unit',
                        userId: widget.userId,
                        courseId: widget.courseId,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedScheduleType = result['scheduleType'] ?? 'daily';
                      _selectedMealTime = result['selectedMealTime'] ?? 'Выбор';
                      _selectedNotification =
                          result['selectedNotification'] ?? 'Выбор';
                    });
                  }
                },
                selectedMealTime: _selectedMealTime,
                onMealTimeSelected: (value) {
                  setState(() {
                    _selectedMealTime = value;
                  });
                },
                selectedNotification: _selectedNotification,
                onNotificationSelected: (value) {
                  setState(() {
                    _selectedNotification = value;
                  });
                },
                selectedScheduleType: _selectedScheduleType,
              ),
              const SizedBox(height: 4.0),
              CourseSelectionBox(
                onSelectCourse: (int? newCourseId) {
                  setState(() {
                    _selectedCourseId = newCourseId;
                  });
                },
                selectedCourseId: _selectedCourseId,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addActionOrHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF197FF2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
                child: const Text('Добавить напоминание'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
