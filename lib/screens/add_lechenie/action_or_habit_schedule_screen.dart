import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';

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
  int _selectedDaysMask = 0;
  int _durationValueForSchedule = 7;
  String _durationUnitForSchedule = 'дней';
  int _breakValue = 7;
  String _breakUnit = 'дней';
  String _selectedScheduleType = 'daily';

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
                children: [
                  buildScheduleOption(
                      'С равными интервалами', 'Например: раз в 3 дня', 0),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                  ),
                  buildScheduleOption(
                      'В определенные дни недели', 'Например: пн, ср и пт', 1),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                  ),
                  buildScheduleOption('Циклично',
                      'Например: 3 недели выполнения, неделя отдыха', 2),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                  ),
                  buildScheduleOption('Однократно', '', 3),
                ],
              ),
            ),
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
                  int selectedDaysMask = DatabaseService.daysToMask([]);
                  if (_selectedScheduleIndex == 1) {
                    // Для weekly нужно преобразовать дни (здесь пустой список как пример, нужно реализовать выбор дней)
                    selectedDaysMask = 0; // Замени на реальную логику
                  }
                  Navigator.pop(context, {
                    'scheduleType': _selectedScheduleType,
                    'intervalValue': _intervalValue,
                    'intervalUnit': _intervalUnit,
                    'selectedDaysMask': selectedDaysMask,
                    'durationValue': _durationValueForSchedule,
                    'durationUnit': _durationUnitForSchedule,
                    'breakValue': _breakValue,
                    'breakUnit': _breakUnit,
                    'selectedMealTime': 'Выбор', // Добавлено для совместимости
                    'selectedNotification':
                        'Выбор', // Добавлено для совместимости
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF197FF2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.0),
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

  Widget buildScheduleOption(String title, String subtitle, int index) {
    return RadioListTile(
      value: index,
      groupValue: _selectedScheduleIndex,
      onChanged: (value) {
        setState(() {
          _selectedScheduleIndex = value!;
          _selectedScheduleType = index == 0
              ? 'interval'
              : index == 1
                  ? 'weekly'
                  : index == 2
                      ? 'cyclic'
                      : 'single';
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
        ),
      ],
    );
  }

  void showIntervalPicker(BuildContext context) {
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
                  'Интервал выполнения',
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
                                _intervalValue = index + 1;
                              });
                            },
                            children: List.generate(30, (index) {
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
                                _intervalUnit =
                                    ['дня', 'дней', 'недель', 'месяцев'][index];
                              });
                            },
                            children: ['дня', 'дней', 'недель', 'месяцев']
                                .map((unit) {
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
            child: buildWeekdayOptions(),
          ),
        ),
      ],
    );
  }

  Widget buildWeekdayOptions() {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          final isSelected =
              (_selectedDaysMask & (1 << days.indexOf(day))) != 0;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDaysMask ^= (1 << days.indexOf(day));
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
      ),
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
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Длительность выполнения',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0B102B),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          showDurationPicker(context, isDuration: true);
                        },
                        child: Row(
                          children: [
                            Text(
                              '$_durationValueForSchedule $_durationUnitForSchedule',
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Длительность перерыва',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0B102B),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          showDurationPicker(context, isDuration: false);
                        },
                        child: Row(
                          children: [
                            Text(
                              '$_breakValue $_breakUnit',
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
        ),
      ],
    );
  }

  void showDurationPicker(BuildContext context, {required bool isDuration}) {
    int selectedNumber = isDuration ? _durationValueForSchedule : _breakValue;
    String selectedUnit = isDuration ? _durationUnitForSchedule : _breakUnit;
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isDuration
                      ? 'Длительность выполнения'
                      : 'Длительность перерыва',
                  style: const TextStyle(
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
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: ListWheelScrollView(
                            itemExtent: 50,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                selectedUnit = ['дней', 'недель'][index];
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
                    if (isDuration) {
                      setState(() {
                        _durationValueForSchedule = selectedNumber;
                        _durationUnitForSchedule = selectedUnit;
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

  Widget buildSingleBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        const Padding(
          padding: EdgeInsets.only(left: 16.0), // Отступ 16 слева
          child: Text(
            'Однократное измерение',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [],
          ),
        ),
      ],
    );
  }
}
