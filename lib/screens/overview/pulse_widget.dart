import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';

class PulseWidget extends StatefulWidget {
  final String userId;

  const PulseWidget({super.key, required this.userId});

  @override
  State<PulseWidget> createState() => PulseWidgetState();
}

class PulseWidgetState extends State<PulseWidget> {
  List<Map<String, dynamic>> pulseData = [];
  bool isLoading = true;

  // Добавляем геттер hasData
  bool get hasData => !pulseData.every((data) => data['value'] == null);

  @override
  void initState() {
    super.initState();
    _loadPulseData();
  }

  Future<void> _loadPulseData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await DatabaseService.getPulseData(widget.userId);
      setState(() {
        pulseData = _prepareWeeklyData(data);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading pulse data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void refresh() {
    _loadPulseData();
  }

  List<Map<String, dynamic>> _prepareWeeklyData(
      List<Map<String, dynamic>> data) {
    final now = DateTime.now();
    final weekDays = List.generate(
        7,
        (i) =>
            now.subtract(Duration(days: 6 - i))); // От 6 дней назад до сегодня
    final weeklyData = <Map<String, dynamic>>[];
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    for (int i = 0; i < 7; i++) {
      final date = DateFormat('yyyy-MM-dd').format(weekDays[i]);
      // Фильтруем все записи за текущий день
      final dayData =
          data.where((item) => item['date'].startsWith(date)).toList();
      double? avgValue;
      if (dayData.isNotEmpty) {
        // Вычисляем среднее значение пульса за день
        final total =
            dayData.map((d) => d['value'] as num).reduce((a, b) => a + b);
        avgValue = total / dayData.length;
      }
      final dayOfWeek = dayNames[weekDays[i].weekday - 1];
      weeklyData.add({
        'date': date,
        'value': avgValue,
        'dayOfWeek': dayOfWeek,
      });
    }
    print('Prepared weekly pulse data: $weeklyData');
    return weeklyData;
  }

  @override
  Widget build(BuildContext context) {
    const maxPulse = 200.0;
    const maxHeight = 140.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pulseData.every((data) => data['value'] == null)
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Средний показатель за 7 дней',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: maxHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: pulseData.map((data) {
                          final double columnHeight = data['value'] != null
                              ? (maxHeight - 20) *
                                  (data['value'] / maxPulse).clamp(0.0, 1.0)
                              : 10.0;
                          return SizedBox(
                            width: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: columnHeight,
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                        242, 25, 141, 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      data['value'] != null
                                          ? '${data['value'].toInt()}'
                                          : '',
                                      style: const TextStyle(
                                        color: Color.fromRGBO(242, 25, 141, 1),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['dayOfWeek'],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }
}
