import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:intl/intl.dart';

class ActionOrHabitScheduleScreen extends StatefulWidget {
  final String name;
  final String unit;
  final String userId;
  final int courseId;
  const ActionOrHabitScheduleScreen({
    super.key,
    required this.name,
    required this.unit,
    required this.userId,
    required this.courseId,
  });

  @override
  State<ActionOrHabitScheduleScreen> createState() =>
      _ActionOrHabitScheduleScreenState();
}

class _ActionOrHabitScheduleScreenState
    extends State<ActionOrHabitScheduleScreen> {
  int _selectedScheduleIndex = 0;
  int _intervalValue = 3;
  String _intervalUnit = 'дня';
  int _durationValue = 7;
  String _durationUnit = 'дней';
  int _breakValue = 7;
  String _breakUnit = 'дней';
  final List<String> _selectedDays = [];
  String _scheduleType = 'interval'; // Default schedule type

  DateTime? _singleExecutionDate;
  TimeOfDay? _singleExecutionTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'График выполнения',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Периодичность выполнения',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8.0),
            buildScheduleOptions(),
            if (_selectedScheduleIndex == 0)
              buildEqualIntervalBox()
            else if (_selectedScheduleIndex == 1)
              buildWeekdayBox()
            else if (_selectedScheduleIndex == 2)
              buildCyclicBox()
            else if (_selectedScheduleIndex == 3)
              buildSingleBox(),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () async {
                  // Преобразуем выбранные дни в битовую маску
                  int selectedDaysMask =
                      DatabaseService.daysToMask(_selectedDays);
                  // Передаем данные обратно
                  Navigator.pop(context, {
                    'selectedScheduleIndex': _selectedScheduleIndex,
                    'intervalValue': _intervalValue,
                    'intervalUnit': _intervalUnit,
                    'selectedDaysMask': selectedDaysMask, // Битовая маска
                    'durationValue': _durationValue,
                    'durationUnit': _durationUnit,
                    'breakValue': _breakValue,
                    'breakUnit': _breakUnit,
                    'scheduleType': _scheduleType,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF197FF2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildScheduleOptions() {
    return Container(
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
        children: [
          buildScheduleOption(
              'С равными интервалами', 'Например: раз в 3 дня', 0),
          Divider(height: 1, color: Colors.grey.shade300),
          buildScheduleOption(
              'В определенные дни недели', 'Например: пн, ср и пт', 1),
          Divider(height: 1, color: Colors.grey.shade300),
          buildScheduleOption(
              'Циклично', 'Например: 3 недели приёма, неделя отдыха', 2),
          Divider(height: 1, color: Colors.grey.shade300),
          buildScheduleOption('Однократно', '', 3),
        ],
      ),
    );
  }

  Widget buildScheduleOption(String title, String subtitle, int index) {
    return RadioListTile(
      value: index,
      groupValue: _selectedScheduleIndex,
      onChanged: (value) {
        setState(() {
          _selectedScheduleIndex = value!;
          if (index == 1) {
            _scheduleType =
                'weekly'; // Установить тип расписания для дней недели
          } else if (index == 0) {
            _scheduleType = 'interval'; // Для равных интервалов
          }
        });
      },
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0B102B),
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            )
          : null,
      activeColor: const Color(0xFF197FF2),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  Widget buildEqualIntervalBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        const Text(
          'Интервал',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8.0),
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
                      'Выполнять раз в',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B102B),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        showIntervalPicker(context);
                      },
                      child: Row(
                        children: [
                          Text(
                            '$_intervalValue $_intervalUnit',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF197FF2),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showIntervalPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 42.0,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            _intervalValue = index + 1;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            return Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize:
                                      _intervalValue == index + 1 ? 24 : 16,
                                  fontWeight: _intervalValue == index + 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                          childCount: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 42.0,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            _intervalUnit = ['дня', 'недели', 'месяца'][index];
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            return Center(
                              child: Text(
                                ['дня', 'недели', 'месяца'][index],
                                style: TextStyle(
                                  fontSize: _intervalUnit ==
                                          ['дня', 'недели', 'месяца'][index]
                                      ? 24
                                      : 16,
                                  fontWeight: _intervalUnit ==
                                          ['дня', 'недели', 'месяца'][index]
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                          childCount: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF197FF2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
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

  Widget buildWeekdayBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        const Text(
          'Выберите дни',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: buildWeekdayOptions(),
        ),
      ],
    );
  }

  Widget buildWeekdayOptions() {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) {
        final isSelected = _selectedDays.contains(day);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(day);
              } else {
                _selectedDays.add(day);
              }
            });
          },
          child: CircleAvatar(
            backgroundColor:
                isSelected ? const Color(0xFF197FF2) : Colors.transparent,
            child: Text(
              day,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildCyclicBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        const Text(
          'Настройте цикл',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
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
              ListTile(
                title: const Text('Длительность приема'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_durationValue $_durationUnit',
                      style: const TextStyle(
                        color: Color(0xFF197FF2),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF197FF2)),
                  ],
                ),
                onTap: () {
                  showDurationPicker(context, isDuration: true);
                },
              ),
              const Divider(height: 1, color: Colors.grey),
              ListTile(
                title: const Text('Длительность перерыва'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_breakValue $_breakUnit',
                      style: const TextStyle(
                        color: Color(0xFF197FF2),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF197FF2)),
                  ],
                ),
                onTap: () {
                  showDurationPicker(context, isDuration: false);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void showDurationPicker(BuildContext context, {required bool isDuration}) {
    int selectedNumber = isDuration ? _durationValue : _breakValue;
    String selectedUnit = isDuration ? _durationUnit : _breakUnit;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 42.0,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            selectedNumber = index + 1;
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            return Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize:
                                      selectedNumber == index + 1 ? 24 : 16,
                                  fontWeight: selectedNumber == index + 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                          childCount: 7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 42.0,
                        onSelectedItemChanged: (int index) {
                          setState(() {
                            selectedUnit = ['дней', 'недель', 'месяцев'][index];
                          });
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            return Center(
                              child: Text(
                                ['дней', 'недель', 'месяцев'][index],
                                style: TextStyle(
                                  fontSize: selectedUnit ==
                                          ['дней', 'недель', 'месяцев'][index]
                                      ? 24
                                      : 16,
                                  fontWeight: selectedUnit ==
                                          ['дней', 'недель', 'месяцев'][index]
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                          childCount: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (isDuration) {
                      setState(() {
                        _durationValue = selectedNumber;
                        _durationUnit = selectedUnit;
                      });
                    } else {
                      setState(() {
                        _breakValue = selectedNumber;
                        _breakUnit = selectedUnit;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF197FF2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
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

  Widget buildSingleBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        const Text(
          'Однократное выполнение',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Выберите дату и время выполнения',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0B102B),
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Дата:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B102B),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _singleExecutionDate = pickedDate;
                          });
                        }
                      },
                      child: Text(
                        _singleExecutionDate == null
                            ? 'Выбрать дату'
                            : DateFormat('dd.MM.yyyy')
                                .format(_singleExecutionDate!),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF197FF2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Время:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B102B),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _singleExecutionTime = pickedTime;
                          });
                        }
                      },
                      child: Text(
                        _singleExecutionTime == null
                            ? 'Выбрать время'
                            : '${_singleExecutionTime!.hour}:${_singleExecutionTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF197FF2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
