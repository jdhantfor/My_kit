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
import '/styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_aptechka/services/notification_service.dart';
import '../custom_snack_bar.dart';

class TableTimeScreen extends StatefulWidget {
  final String name;
  final String unit;
  final String userId;
  final int courseId;
  final Map<String, dynamic>? reminderData;
  final bool fromUnattachedReminder; // Новый флаг

  const TableTimeScreen({
    super.key,
    required this.name,
    required this.unit,
    required this.userId,
    required this.courseId,
    this.reminderData,
    this.fromUnattachedReminder = false, // По умолчанию false
  });

  @override
  _TableTimeScreenState createState() => _TableTimeScreenState();
}

class _TableTimeScreenState extends State<TableTimeScreen> {
  bool _isLifelong = true;
  DateTime _startDate = DateTime.now();
  int _durationValue = 30;
  String _durationUnit = 'дней';
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 365));
  final List<Map<String, dynamic>> _timesAndDosages = [];
  int _quantity = 1;
  String _selectedMealTime = 'Выбор';
  String _selectedNotification = 'Выбор';
  int? _selectedCourseId;

  int _intervalValue = 3;
  String _intervalUnit = 'дня';
  int _selectedDaysMask = 0;
  int _durationValueForSchedule = 7;
  String _durationUnitForSchedule = 'дней';
  int _breakValue = 7;
  String _breakUnit = 'дней';
  String _selectedScheduleType = 'daily';

  bool _isStartDateChanged = false;
  bool _isQuantityChanged = false;

  final double horizontalPadding = 12.0;
  final double verticalPadding = 12.0;
  final double sectionSpacing = 16.0;
  final double dividerHorizontalPadding = 16.0;
  final double listTileVerticalPadding = 0.0;
  final double iconSize = 20.0;
  final double appBarTopPadding = 40.0;
  final double appBarTitleSpacing = 8.0;
  final double buttonHeight = 48.0;
  final double durationPickerHeight = 320.0;
  final double durationPickerItemHeight = 50.0;

  @override
void initState() {
  super.initState();
  print('TableTimeScreen: initState started');
  _selectedCourseId = widget.courseId;

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

    // Используем allTimesAndDosages, если оно есть, иначе берём только одну запись
    final timesAndDosages = reminder['allTimesAndDosages'] as List<dynamic>? ??
        [
          {
            'time': reminder['selectTime'],
            'dosage': reminder['dosage'],
            'unit': reminder['unit'],
          }
        ];

    for (final timeAndDosage in timesAndDosages) {
      _timesAndDosages.add({
        'time': timeAndDosage['time'],
        'dosage': int.tryParse(timeAndDosage['dosage'].toString()) ?? 1,
        'unit': timeAndDosage['unit'] ?? widget.unit,
      });
    }

    _intervalValue =
        int.tryParse(reminder['interval_value']?.toString() ?? '3') ?? 3;
    _intervalUnit = reminder['interval_unit'] ?? 'дня';
    _selectedDaysMask =
        int.tryParse(reminder['selected_days_mask']?.toString() ?? '0') ?? 0;
    _durationValueForSchedule =
        int.tryParse(reminder['cycle_duration']?.toString() ?? '7') ?? 7;
    _breakValue = int.tryParse(reminder['cycle_break']?.toString() ?? '7') ?? 7;

    _durationUnitForSchedule = reminder['cycle_break_unit'] ?? 'дней';
    _breakUnit = reminder['cycle_break_unit'] ?? 'дней';
    _selectedScheduleType = reminder['schedule_type'] ?? 'daily';
    _isStartDateChanged = true;
  }
}

  void _addReminder() async {
  final userId = Provider.of<UserProvider>(context, listen: false).userId;
  if (userId == null) {
    showCustomSnackBar(context, 'Пожалуйста, войдите в систему'
    );
    return;
  }
  print('TableTimeScreen: userId: $userId');

  DateTime? endDate;
  if (_selectedScheduleType == 'single') {
    endDate = _startDate;
    _isLifelong = false;
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
  print('TableTimeScreen: endDate: $endDate');

  int? medicineId;

  if (_isQuantityChanged && _quantity > 0) {
    print('TableTimeScreen: Quantity changed, updating medicine');
    try {
      final databaseService = DatabaseService();
      final medicines = await databaseService.getMedicines(userId, userId);
      final existingMedicine = medicines.firstWhere(
        (medicine) => medicine['name'] == widget.name,
        orElse: () => <String, dynamic>{},
      );

      if (existingMedicine.isNotEmpty) {
        medicineId = existingMedicine['id'];
        await databaseService.updateMedicineQuantity(userId, medicineId!, _quantity);
        await databaseService.updateMedicineUnit(userId, medicineId, widget.unit);
      } else {
        medicineId = await databaseService.addMedicine(
          widget.name,
          null,
          null,
          null,
          _quantity,
          userId,
          unit: widget.unit,
        );
      }
    } catch (e) {
      print('TableTimeScreen: Error updating/adding medicine: $e');
      showCustomSnackBar(context,'Ошибка при обновлении лекарства: $e'
      );
      return;
    }
  }

  final databaseService = DatabaseService();

  // Если редактируем существующее напоминание, удаляем старые записи и уведомления
  if (widget.reminderData != null) {
    await databaseService.deleteRemindersByNameAndCourseId(
      widget.name,
      _selectedCourseId!,
      userId,
    );
    print('TableTimeScreen: Old notifications cancelled');
  }

  // Создаём напоминания для каждого элемента в _timesAndDosages
  try {
    // Сохраняем напоминания в базе данных и собираем их ID
    final reminderIds = <int>[];
    for (var timeAndDosage in _timesAndDosages) {
      final reminderData = {
        'name': widget.name,
        'time': _selectedMealTime,
        'dosage': timeAndDosage['dosage'].toString(),
        'unit': widget.unit,
        'selectTime': timeAndDosage['time'],
        'startDate': DateFormat('yyyy-MM-dd').format(_startDate),
        'endDate': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
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
        'medicineId': medicineId,
      };

      reminderData.removeWhere((key, value) => value == null);
      print('TableTimeScreen: Adding reminder with data: $reminderData');

      final insertedReminderId = await databaseService.addReminder(reminderData, userId);
      reminderIds.add(insertedReminderId);
      print('TableTimeScreen: Reminder added with ID: $insertedReminderId');
    }

    // Планируем уведомления
    final schedule = {
      'scheduleType': _selectedScheduleType,
      'endDate': endDate,
      'timesAndDosages': _timesAndDosages,
      'intervalValue': _intervalValue,
      'intervalUnit': _intervalUnit,
      'selectedDays': _selectedDaysMask.toString(),
      'cycleDuration': _durationValueForSchedule,
      'cycleBreak': _breakValue,
    };

    // Планируем уведомления для каждого reminderId
    for (var reminderId in reminderIds) {
      await NotificationService.scheduleNotifications(
        reminderId: reminderId,
        name: widget.name,
        startDate: _startDate,
        schedule: schedule,
        type: NotificationService.medicationType,
      );
      print('TableTimeScreen: Notifications scheduled for reminderId: $reminderId');
    }

    // Показываем один общий SnackBar после успешного планирования
    showCustomSnackBar(context, 'Уведомления запланированы');
  } catch (e) {
    print('TableTimeScreen: Error adding reminders or scheduling notifications: $e');
    showCustomSnackBar(context, 'Ошибка при добавлении напоминаний: $e'
    );
    return;
  }

  print('TableTimeScreen: Navigating to HomeScreen');
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

  @override
  Widget build(BuildContext context) {
    print('TableTimeScreen: build started');
    final userId = Provider.of<UserProvider>(context).userId;
    if (userId == null) {
      print('TableTimeScreen: userId is null in build');
      return const Scaffold(
        body: Center(child: Text('Пожалуйста, войдите в систему')),
      );
    }
    print('TableTimeScreen: userId in build: $userId');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
  Padding(
    padding: EdgeInsets.only(
      top: appBarTopPadding, // Отступ сверху для AppBar
      left: 12, // Отступ слева
      right: horizontalPadding, // Отступ справа
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/arrow_back.svg',
                width: iconSize + 4,
                height: iconSize + 4,
              ),
              SizedBox(width: appBarTitleSpacing),
              Text(
                truncateText(widget.name, 19), 
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        if (widget.fromUnattachedReminder) ...[
          Spacer(),
          InkWell(
            onTap: () {
              _showMoreMenu(context);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                'assets/more.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ],
      ],
    ),
  ),
            SizedBox(height: verticalPadding),
              // Длительность приема
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: 16.0,
                          bottom: 8), // Сдвигаем только текст на 16 вправо
                      child: Text(
                        'Длительность приема',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.secondaryGrey,
                            ),
                      ),
                    ),
                    const SizedBox(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(8.0), // Внутренние отступы 4
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Бессрочно',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: _isLifelong,
                                      onChanged: (value) {
                                        setState(() {
                                          _isLifelong = value;
                                          _toggleDurationPicker();
                                        });
                                      },
                                      activeColor: Colors.white,
                                      activeTrackColor: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: dividerHorizontalPadding),
                              child: const Divider(
                                color: AppColors.fieldBackground,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: verticalPadding,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Начало приема',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
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
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.primaryBlue,
                                              ),
                                        ),
                                        SizedBox(width: appBarTitleSpacing),
                                        SvgPicture.asset(
                                          'assets/arrow_forward_blue.svg',
                                          width: iconSize,
                                          height: iconSize,
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
                                    padding: EdgeInsets.symmetric(
                                        horizontal: dividerHorizontalPadding),
                                    child: const Divider(
                                      color: AppColors.fieldBackground,
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: horizontalPadding,
                                      vertical: verticalPadding,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Срок приема',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        InkWell(
                                          onTap: () {
                                            _showDurationPicker(context);
                                          },
                                          child: Row(
                                            children: [
                                              Text(
                                                '$_durationValue $_durationUnit',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.primaryBlue,
                                                    ),
                                              ),
                                              SizedBox(
                                                  width: appBarTitleSpacing),
                                              SvgPicture.asset(
                                                'assets/arrow_forward_blue.svg',
                                                width: iconSize,
                                                height: iconSize,
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
                  ],
                ),
              ),
              // Время и дозировка
              SizedBox(height: sectionSpacing),
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
              // ScheduleBox
              SizedBox(height: sectionSpacing),
              ScheduleBox(
                onNavigateToScheduleScreen: () async {
                  final result = await _navigateToScheduleScreen(context);
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
              SizedBox(height: sectionSpacing),
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
                  print('TableTimeScreen: Quantity changed to: $value');
                  setState(() {
                    _quantity = value;
                    _isQuantityChanged = true;
                  });
                },
              ),
              // Лечение по курсу
              SizedBox(height: sectionSpacing),
              TreatmentCourseBox(
                onSelectCourse: _selectCourse,
                selectedCourseId: _selectedCourseId,
              ),
              // Кнопка добавления напоминания
              SizedBox(height: sectionSpacing),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ElevatedButton(
                  onPressed: _addReminder,
                  style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                        minimumSize: MaterialStateProperty.all(
                            Size.fromHeight(buttonHeight)),
                      ),
                  child: const Text('Добавить напоминание'),
                ),
              ),
              SizedBox(height: sectionSpacing),
            ],
          ),
        ),
      ),
    );
  }
String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }
  
  void _showMoreMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить'),
              onTap: () {
                Navigator.pop(context); // Закрываем меню
                _deleteReminder();
              },
            ),
          ],
        ),
      );
    },
  );
}

void _deleteReminder() async {
  if (widget.reminderData == null || widget.reminderData!['id'] == null) {
    showCustomSnackBar(context, 'Ошибка: Напоминание не найдено');
    return;
  }

  final reminderId = widget.reminderData!['id'];
  final userId = widget.userId;

  try {
    final databaseService = DatabaseService();
    await databaseService.delReminder(reminderId, userId);
    print('Напоминание с id $reminderId успешно удалено из локальной базы');
    // Уведомляем UserProvider об изменении данных
    Provider.of<UserProvider>(context, listen: false).notifyDataChanged();
    Navigator.pop(context);
  } catch (e) {
    print('Ошибка при удалении напоминания: $e');
    showCustomSnackBar(context, 'Ошибка при удалении напоминания: $e');
  }
}

  void _showDatePicker(BuildContext context) async {
    print('TableTimeScreen: _showDatePicker called');
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

  bool _showDurationPickerInside = false;

  void _toggleDurationPicker() {
    setState(() {
      _showDurationPickerInside = !_showDurationPickerInside;
    });
  }

  void _showDurationPicker(BuildContext context) {
    print('TableTimeScreen: _showDurationPicker called');
    int selectedNumber = _durationValue;
    String selectedUnit = _durationUnit;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: durationPickerHeight,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Text(
                  'Длительность приёма',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding),
                          child: Container(
                            width: double.infinity,
                            height: durationPickerItemHeight,
                            decoration: BoxDecoration(
                              color: AppColors.secondaryGrey.withOpacity(0.2),
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
                            itemExtent: durationPickerItemHeight,
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
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }),
                          ),
                        ),
                        SizedBox(width: horizontalPadding),
                        Expanded(
                          flex: 1,
                          child: ListWheelScrollView(
                            itemExtent: durationPickerItemHeight,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedUnit = index == 0 ? 'дней' : 'недель';
                              });
                            },
                            children: ['дней', 'недель'].map((unit) {
                              return Center(
                                child: Text(
                                  unit,
                                  style: Theme.of(context).textTheme.bodyMedium,
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
                padding: EdgeInsets.all(horizontalPadding),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _durationValue = selectedNumber;
                      _durationUnit = selectedUnit;

                      if (_durationUnit == 'недель') {
                        _durationValue *= 7;
                        _durationUnit = 'дней';
                      }

                      print(
                          'TableTimeScreen: Выбранная длительность: $_durationValue $_durationUnit');
                    });
                  },
                  style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                        minimumSize: MaterialStateProperty.all(
                            Size(double.infinity, buttonHeight)),
                      ),
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _navigateToScheduleScreen(
      BuildContext context) async {
    print('TableTimeScreen: _navigateToScheduleScreen called');
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
      print('TableTimeScreen: ScheduleScreen result: $result');
      return result;
    } else {
      print('TableTimeScreen: userId is null in _navigateToScheduleScreen');
      showCustomSnackBar(context, 'Пожалуйста, войдите в систему'
      );
      return null;
    }
  }
}
