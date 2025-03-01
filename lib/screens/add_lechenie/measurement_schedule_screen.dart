import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';

class MeasurementScheduleScreen extends StatefulWidget {
  final String name;
  final String unit;
  final String userId;
  final int courseId;
  const MeasurementScheduleScreen({
    super.key,
    required this.name,
    required this.unit,
    required this.userId,
    required this.courseId,
  });

  @override
  State createState() => _MeasurementScheduleScreenState();
}

class _MeasurementScheduleScreenState extends State {
  int _selectedScheduleIndex = 0;
  int _intervalValue = 3;
  String _intervalUnit = 'дня';
  int _durationValue = 7;
  String _durationUnit = 'дней';
  int _breakValue = 7;
  String _breakUnit = 'дней';
  final List<String> _selectedDays = [];
  String _scheduleType = 'interval'; // Default schedule type

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
          'График измерений',
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
              'Периодичность измерений',
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
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Принимать раз в',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0B102B),
        ),
      ),
      InkWell(
        onTap: () {
          _showIntervalPicker(context);
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
      ],
    );
  }

  void _showIntervalPicker(BuildContext context) {
  int selectedNumber = _intervalValue;
  String selectedUnit = _intervalUnit;

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
                'Принимать раз в',
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
                    mainAxisAlignment: MainAxisAlignment.center, // Центрирование
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
                    _intervalValue = selectedNumber;
                    _intervalUnit = selectedUnit;

                    // Конвертация в дни
                    if (_intervalUnit == 'Недель') {
                      _intervalValue *= 7; // Если недели, то умножаем на 7
                      _intervalUnit = 'Дней'; // Всегда храним в днях
                    }

                    print('Выбранный интервал: $_intervalValue $_intervalUnit');
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
        height: 320,
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                isDuration ? 'Длительность приёма' : 'Длительность перерыва',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Колеса выбора
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
                      const SizedBox(width: 16),
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
                    if (isDuration) {
                      _durationValue = selectedNumber;
                      _durationUnit = selectedUnit;
                    } else {
                      _breakValue = selectedNumber;
                      _breakUnit = selectedUnit;
                    }

                    // Конвертация в дни
                    if (_durationUnit == 'Недель') {
                      _durationValue *= 7; // Если недели, то умножаем на 7
                      _durationUnit = 'Дней'; // Всегда храним в днях
                    }
                    if (_breakUnit == 'Недель') {
                      _breakValue *= 7; // Если недели, то умножаем на 7
                      _breakUnit = 'Дней'; // Всегда храним в днях
                    }

                    print('Выбранная длительность: $_durationValue $_durationUnit');
                    print('Выбранный перерыв: $_breakValue $_breakUnit');
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

  Widget buildSingleBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        const Text(
          'Однократное измерение',
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [],
          ),
        ),
      ],
    );
  }
}
