import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'schedule_screen.dart';
import 'table_time/dosage_box.dart';
import 'table_time/schedule_box.dart';
import 'table_time/quantity_and_expiration_box.dart';
import 'table_time/treatment_course_box.dart';
import 'database_service.dart';
import 'home_screen.dart';
import 'user_provider.dart';

class TableTimeScreen extends StatefulWidget {
  final String name;
  final String unit;
  final String userId;
  final int courseId;
  final Map<String, dynamic>? reminderData; // Данные существующего напоминания

  const TableTimeScreen({
    super.key,
    required this.name,
    required this.unit,
    required this.userId,
    required this.courseId,
    this.reminderData, // Необязательный параметр
  });

  @override
  _TableTimeScreenState createState() => _TableTimeScreenState();
}

class _TableTimeScreenState extends State<TableTimeScreen> {
  bool _isLifelong = true;
  DateTime _startDate = DateTime.now(); // По умолчанию текущая дата
  int _durationValue = 30;
  String _durationUnit = 'дней';
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 365));
  final List<Map<String, dynamic>> _timesAndDosages = [];
  int _quantity = 1;
  String _selectedMealTime = 'Выбор';
  String _selectedNotification = 'Выбор';
  int? _selectedCourseId;

  // Добавляем эти поля:
  int _intervalValue = 3;
  String _intervalUnit = 'дня';
  int _selectedDaysMask = 0;
  int _durationValueForSchedule = 7;
  String _durationUnitForSchedule = 'дней';
  int _breakValue = 7;
  String _breakUnit = 'дней';
  String _selectedScheduleType = 'daily';

  // Флаг для отслеживания, была ли дата изменена пользователем
  bool _isStartDateChanged = false;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.courseId;

    // Если переданы данные напоминания, заполняем поля
    if (widget.reminderData != null) {
      final reminder = widget.reminderData!;
      _isLifelong = reminder['isLifelong'] == 1;
      _startDate = DateTime.parse(reminder['startDate']);
      _durationValue =
          int.tryParse(reminder['duration']?.toString() ?? '30') ?? 30;
      _durationUnit = reminder['durationUnit'] ?? 'дней';
      _expirationDate = reminder['endDate'] != null
          ? DateTime.parse(reminder['endDate'])
          : DateTime.now().add(const Duration(days: 365));

      // Заполняем времена и дозировки
      final timesAndDosages =
          reminder['timesAndDosages'] as List<dynamic>? ?? [];
      for (final timeAndDosage in timesAndDosages) {
        _timesAndDosages.add({
          'time': timeAndDosage['time'],
          'dosage': timeAndDosage['dosage'],
        });
      }

      // Заполняем другие параметры
      _intervalValue =
          int.tryParse(reminder['interval_value']?.toString() ?? '3') ?? 3;
      _intervalUnit = reminder['interval_unit'] ?? 'дня';
      _selectedDaysMask =
          int.tryParse(reminder['selected_days_mask']?.toString() ?? '0') ?? 0;
      _durationValueForSchedule =
          int.tryParse(reminder['cycle_duration']?.toString() ?? '7') ?? 7;
      _breakValue =
          int.tryParse(reminder['cycle_break']?.toString() ?? '7') ?? 7;

      // Исправление: правильно обрабатываем cycle_break_unit
      _durationUnitForSchedule =
          reminder['cycle_break_unit'] ?? 'дней'; // Используем правильное поле
      _breakUnit =
          reminder['cycle_break_unit'] ?? 'дней'; // То же самое для breakUnit

      _selectedScheduleType = reminder['schedule_type'] ?? 'daily';
      _isStartDateChanged =
          true; // Если данные загружены, считаем, что дата изменена
    }
  }

  void _addReminder() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId == null) {
      print('User is not logged in');
      return;
    }

    // Определяем дату окончания приема
    DateTime? endDate;
    if (_selectedScheduleType == 'single') {
      // Для однократного приёма endDate = startDate
      endDate = _startDate;
      _isLifelong = false; // Однократный приём не может быть бессрочным
    } else if (!_isLifelong) {
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

    // Подготавливаем данные для записи
    final reminderData = {
      'name': widget.name,
      'time': _selectedMealTime,
      'dosage': _timesAndDosages.isNotEmpty
          ? _timesAndDosages[0]['dosage'].toString()
          : '',
      'unit': widget.unit,
      'selectTime':
          _timesAndDosages.isNotEmpty ? _timesAndDosages[0]['time'] : null,
      'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
      'endDate':
          endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
      'isLifelong': _isLifelong ? 1 : 0,
      'schedule_type': _selectedScheduleType,
      'interval_value': _intervalValue,
      'interval_unit': _intervalUnit,
      'selected_days_mask': _selectedDaysMask,
      'cycle_duration': _durationValueForSchedule,
      'cycle_break': _breakValue,
      'cycle_break_unit': _breakUnit,
      'courseid': _selectedCourseId,
      'user_id': userId,
    };

    // Удаляем null значения
    reminderData.removeWhere((key, value) => value == null);

    // Добавляем напоминание в базу данных
    final databaseService = DatabaseService();
    await databaseService.addReminder(reminderData, userId);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(initialIndex: 0),
      ),
    );
  }

  void _selectCourse(int? courseId) {
    setState(() {
      _selectedCourseId = courseId;
    });
  }

  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Пожалуйста, войдите в систему')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          widget.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Длительность приема
              const SizedBox(height: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0), // Отступ 16 слева
                    child: Text(
                      'Длительность приема',
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
                                    _toggleDurationPicker();
                                  });
                                },
                                activeColor: Colors
                                    .white, // Белый кружочек в активном состоянии
                                activeTrackColor: const Color(
                                    0xFF197FF2), // Синий фон в активном состоянии
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: const Divider(
                            color: Color(0xFFE0E0E0),
                            thickness: 1,
                          ),
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
                                'Начало приема',
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
                                          : 'Сегодня', // По умолчанию "Сегодня"
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
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: const Divider(
                                  color: Color(0xFFE0E0E0),
                                  thickness: 1,
                                ),
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
                                      'Срок приема',
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
                ],
              ),

              // Время и дозировка
              DosageBox(
                timesAndDosages: _timesAndDosages,
                onTimeAndDosageAdded: (time, dosage) {
                  setState(() {
                    _timesAndDosages.add({
                      'time': time,
                      'dosage': dosage,
                      'unit': widget.unit,
                    });
                  });
                },
                onTimeAndDosageUpdated: (index, dosage) {
                  setState(() {
                    _timesAndDosages[index]['dosage'] = dosage;
                  });
                },
                onTimeAndDosageRemoved: (index) {
                  setState(() {
                    _timesAndDosages.removeAt(index);
                  });
                },
              ),

              // ScheduleBox с учетом изменений
              const SizedBox(height: 16.0),
              ScheduleBox(
                onNavigateToScheduleScreen: () async {
                  final result = await _navigateToScheduleScreen(
                      context); // Используем исправленный метод
                  if (result != null && mounted) {
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

              // Количество и срок годности
              const SizedBox(height: 16.0),
              QuantityAndExpirationBox(
                unit: widget.unit,
                expirationDate: _expirationDate,
                onExpirationDateChanged: (date) {
                  setState(() {
                    _expirationDate = date;
                  });
                },
                quantity: _quantity,
                onQuantityChanged: (value) {
                  setState(() {
                    _quantity = value;
                  });
                },
              ),

              // Лечение по курсу
              const SizedBox(height: 16.0),
              TreatmentCourseBox(
                onSelectCourse: _selectCourse,
                selectedCourseId: _selectedCourseId,
              ),

              // Кнопка добавления напоминания
              const SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _addReminder,
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
              ),
            ],
          ),
        ),
      ),
    );
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
        _isStartDateChanged = true; // Пользователь изменил дату
      });
    }
  }

  bool _showDurationPickerInside = false;

  void _toggleDurationPicker() {
    setState(() {
      _showDurationPickerInside = !_showDurationPickerInside;
    });
  }

  void _showDurationPicker(BuildContext context) {
    int selectedNumber = _durationValue;
    String selectedUnit = _durationUnit;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              // Заголовок
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Длительность приёма',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Колеса выбора
              Expanded(
                child: Stack(
                  children: [
                    // Общая серая полоска на заднем плане
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
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Центрирование
                      children: [
                        // Числа (1-7)
                        Expanded(
                          flex: 1,
                          child: ListWheelScrollView(
                            itemExtent: 50,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedNumber = index + 1;
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
                        SizedBox(width: 16), // Пространство между колесами
                        // Единицы измерения (Дней/Недель)
                        Expanded(
                          flex: 1,
                          child: ListWheelScrollView(
                            itemExtent: 50,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedUnit = index == 0 ? 'Дней' : 'Недель';
                              });
                            },
                            children: ['Дней', 'Недель'].map((unit) {
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
              // Кнопка "Сохранить"
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _durationValue = selectedNumber;
                      _durationUnit = selectedUnit;

                      // Конвертация в дни
                      if (_durationUnit == 'Недель') {
                        _durationValue *= 7; // Если недели, то умножаем на 7
                        _durationUnit = 'Дней'; // Всегда храним в днях
                      }

                      print(
                          'Выбранная длительность: $_durationValue $_durationUnit');
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

  // Метод для получения данных из ScheduleScreen
  Future<Map<String, dynamic>?> _navigateToScheduleScreen(
      BuildContext context) async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    if (userId != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleScreen(
            name: widget.name,
            unit: widget.unit,
            userId: userId,
            courseId: widget.courseId,
          ),
        ),
      );
      return result; // Возвращаем результат навигации
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, войдите в систему')),
      );
      return null; // Если пользователь не авторизован, возвращаем null
    }
  }
}
