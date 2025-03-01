import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';

class StepsWidget extends StatefulWidget {
  final String userId;

  const StepsWidget({super.key, required this.userId});

  @override
  State<StepsWidget> createState() => StepsWidgetState();
}

class StepsWidgetState extends State<StepsWidget> {
  List<Map<String, dynamic>> stepsData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStepsData();
  }

  Future<void> _loadStepsData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await DatabaseService.getStepsData(widget.userId);
      setState(() {
        stepsData = _prepareWeeklyData(data);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading steps data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _prepareWeeklyData(List<Map<String, dynamic>> data) {
    final now = DateTime.now();
    final weekDays = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final weeklyData = <Map<String, dynamic>>[];
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    for (int i = 0; i < 7; i++) {
      final date = DateFormat('yyyy-MM-dd').format(weekDays[i]);
      final dayData = data.firstWhere(
        (item) => item['date'].startsWith(date),
        orElse: () => {'date': date, 'count': null},
      );
      weeklyData.add({
        'date': date,
        'count': dayData['count'],
        'dayOfWeek': dayNames[weekDays[i].weekday - 1],
      });
    }
    return weeklyData;
  }

  void refresh() {
    _loadStepsData();
  }

  @override
  Widget build(BuildContext context) {
    const maxSteps = 50000.0;
    const maxHeight = 140.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : stepsData.every((data) => data['count'] == null)
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'За последние 7 дней',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: maxHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: stepsData.map((data) {
                          final double columnHeight = data['count'] != null
                              ? (maxHeight - 20) * (data['count'] / maxSteps).clamp(0.0, 1.0)
                              : 10.0;
                          return SizedBox(
                            width: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: columnHeight,
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(242, 162, 25, 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      data['count'] != null
                                          ? '${(data['count'] / 1000).toStringAsFixed(1)}k'
                                          : '',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 10,
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