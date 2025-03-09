import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'measurement_dosage_box.dart';
import 'measurement_schedule_box.dart';
import 'measurement_schedule_screen.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'course_selection_box.dart';
import 'package:my_aptechka/screens/home_screen.dart'; // Импорт HomeScreen

class MeasurementSettingsScreen extends StatefulWidget {
  final String userId;
  final int courseId;
  final String measurementType;

  const MeasurementSettingsScreen({
    super.key,
    required this.userId,
    required this.courseId,
    required this.measurementType,
  });

  @override
  MeasurementSettingsScreenState createState() =>
      MeasurementSettingsScreenState();
}

class MeasurementSettingsScreenState extends State<MeasurementSettingsScreen> {
  bool _isLifelong = true;
  DateTime _startDate = DateTime.now();
  int _durationValue = 30;
  String _durationUnit = 'дней';
  final List<Map<String, dynamic>> _times = [];
  String _selectedMealTime = 'Выбор';
  String _selectedNotification = 'Выбор';
  int? _selectedCourseId;

  // Добавляем эти поля для расписания
  int _intervalValue = 3;
  String _intervalUnit = 'дня';
  int _selectedDaysMask = 0;
  int _durationValueForSchedule = 7;
  String _durationUnitForSchedule = 'дней';
  int _breakValue = 7;
  String _breakUnit = 'дней';
  String _selectedScheduleType = 'daily';

  // Флаг для отслеживания изменения даты
  bool _isStartDateChanged = false;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
  }

  void _addMeasurement() async {
    int courseId = _selectedCourseId ?? -1;

    DateTime? endDate;
    if (!_isLifelong) {
      if (_durationUnit == 'дней') {
        endDate = _startDate.add(Duration(days: _durationValue - 1));
      } else if (_durationUnit == 'недель') {
        endDate = _startDate.add(Duration(days: _durationValue * 7 - 1));
      }
    }

    final measurementData = {
      'name': widget.measurementType,
      'time': _selectedMealTime,
      'selectTime': _times.isNotEmpty ? _times[0]['time'] : null,
      'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
      'endDate':
          endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
      'isLifelong': _isLifelong ? 1 : 0,
      'schedule_type': _selectedScheduleType,
      'interval_value': _intervalValue,
      'interval_unit': 'дней',
      'selected_days_mask': _selectedDaysMask,
      'cycle_duration': _durationValueForSchedule,
      'cycle_break': _breakValue,
      'cycle_break_unit': 'дней',
      'courseid': courseId,
      'user_id': widget.userId,
    };

    try {
      await DatabaseService.addMeasurement(measurementData, widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Измерение добавлено')),
      );

      // После успешного добавления переходим на HomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false, // Удаляем все предыдущие экраны
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
                  'Срок измерений',
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
                      print('Выбранный срок: $_durationValue $_durationUnit');
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
        title: Text(widget.measurementType),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: const Text(
                  'Длительность измерений',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
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
                                });
                              },
                              activeColor: Colors.white, // Белый кружок
                              activeTrackColor:
                                  const Color(0xFF197FF2), // Синяя дорожка
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child:
                          const Divider(color: Color(0xFFE0E0E0), thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Начало измерений',
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
                    if (!_isLifelong)
                      Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: const Divider(
                                color: Color(0xFFE0E0E0), thickness: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Срок измерений',
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
              const SizedBox(height: 16.0),
              MeasurementDosageBox(
                timesAndDosages: _times,
                onTimeAdded: (time) {
                  setState(() {
                    _times.add({'time': time});
                  });
                },
                onTimeUpdated: (index, time) {
                  setState(() {
                    _times[index]['time'] = time;
                  });
                },
                onTimeRemoved: (index) {
                  setState(() {
                    _times.removeAt(index);
                  });
                },
              ),
              const SizedBox(height: 16.0),
              MeasurementScheduleBox(
                onNavigateToScheduleScreen: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MeasurementScheduleScreen(
                        name: widget.measurementType,
                        unit: 'unit',
                        userId: widget.userId,
                        courseId: widget.courseId,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedScheduleType = result['scheduleType'] ?? 'daily';
                      _intervalValue = result['intervalValue'] ?? 3;
                      _intervalUnit = result['intervalUnit'] ?? 'дня';
                      _selectedDaysMask = result['selectedDaysMask'] ?? 0;
                      _durationValueForSchedule = result['durationValue'] ?? 7;
                      _durationUnitForSchedule =
                          result['durationUnit'] ?? 'дней';
                      _breakValue = result['breakValue'] ?? 7;
                      _breakUnit = result['breakUnit'] ?? 'дней';
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
              const SizedBox(height: 16.0),
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
                onPressed: _addMeasurement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF197FF2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
                child: const Text('Добавить измерение'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
