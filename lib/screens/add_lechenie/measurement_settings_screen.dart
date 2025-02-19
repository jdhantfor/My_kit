import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'measurement_dosage_box.dart';
import 'measurement_schedule_box.dart';
import 'measurement_schedule_screen.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'course_selection_box.dart'; // Импортируем новый виджет
import 'dart:convert';

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
  List<Map<String, dynamic>> _times = [];
  String _selectedMealTime = 'Выбор';
  String _selectedNotification = 'Выбор';
  int? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;
  }

  void _addMeasurement() async {
    int courseId =
        _selectedCourseId ?? -1; // Если курс не выбран, используем -1

    DateTime? endDate;
    if (!_isLifelong) {
      if (_durationUnit == 'дней') {
        endDate = _startDate.add(Duration(days: _durationValue - 1));
      } else if (_durationUnit == 'месяцев') {
        endDate = DateTime(
          _startDate.year + (_durationValue * _startDate.month ~/ 12),
          (_startDate.month + _durationValue - 1) % 12 + 1,
          _startDate.day,
        );
      }
    }

    final measurementData = {
      'name': widget.measurementType,
      'isLifelong': _isLifelong,
      'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
      'endDate':
          endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
      'courseid': courseId,
      'user_id': widget.userId,
      'mealTime': _selectedMealTime,
      'times': jsonEncode(_times
          .map((time) => time['time'])
          .toList()), // Конвертируем список времен в JSON
    };

    try {
      await DatabaseService.addMeasurement(measurementData, widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Измерение добавлено')),
      );
      Navigator.pop(context);
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
      });
    }
  }

  void _showDurationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Дней'),
                onTap: () {
                  setState(() {
                    _durationUnit = 'дней';
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Месяцев'),
                onTap: () {
                  setState(() {
                    _durationUnit = 'месяцев';
                  });
                  Navigator.pop(context);
                },
              ),
              Slider(
                value: _durationValue.toDouble(),
                min: 1,
                max: 365,
                divisions: 364,
                label: _durationValue.toString(),
                onChanged: (double value) {
                  setState(() {
                    _durationValue = value.toInt();
                  });
                },
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
              const Text(
                'Длительность измерений',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                          Switch(
                            value: _isLifelong,
                            onChanged: (value) {
                              setState(() {
                                _isLifelong = value;
                              });
                            },
                            activeColor: const Color(0xFF197FF2),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Color(0xFFE0E0E0), thickness: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
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
                                  DateFormat('dd.MM.yyyy').format(_startDate),
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
              ),
              if (!_isLifelong)
                Column(
                  children: [
                    const Divider(color: Color(0xFFE0E0E0), thickness: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
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
                        unit: 'unit', // Замените на актуальное значение
                        userId: widget.userId,
                        courseId: widget.courseId,
                      ),
                    ),
                  );
                  if (result != null) {
                    // Обработка результата, если нужно
                    setState(() {
                      // Обновите состояние на основе полученных данных
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
                selectedScheduleType: 'daily', // Замените на нужное значение
              ),
              const SizedBox(height: 16.0),
              CourseSelectionBox(
                // Добавляем виджет для выбора курса
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
                child: const Text('Добавить напоминание'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
