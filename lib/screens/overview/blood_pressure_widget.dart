import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';

class BloodPressureWidget extends StatefulWidget {
  final String userId;

  const BloodPressureWidget({super.key, required this.userId});

  @override
  State<BloodPressureWidget> createState() => BloodPressureWidgetState(); // Сделали класс публичным
}

class BloodPressureWidgetState extends State<BloodPressureWidget> {
  List<Map<String, dynamic>> bloodPressureData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBloodPressureData();
  }

  Future<void> _loadBloodPressureData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await DatabaseService.getBloodPressureData(widget.userId);
      setState(() {
        bloodPressureData = _prepareWeeklyData(data);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading blood pressure data: $e');
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
      final dayData = data.where((item) => item['date'].startsWith(date)).toList();
      if (dayData.isNotEmpty) {
        final avgSystolic = dayData.map((d) => d['systolic']).reduce((a, b) => a + b) / dayData.length;
        final avgDiastolic = dayData.map((d) => d['diastolic']).reduce((a, b) => a + b) / dayData.length;
        weeklyData.add({
          'date': date,
          'systolic': avgSystolic,
          'diastolic': avgDiastolic,
          'dayOfWeek': dayNames[weekDays[i].weekday - 1],
        });
      } else {
        weeklyData.add({
          'date': date,
          'systolic': null,
          'diastolic': null,
          'dayOfWeek': dayNames[weekDays[i].weekday - 1],
        });
      }
    }
    return weeklyData;
  }

  void refresh() {
    _loadBloodPressureData();
  }

  @override
  Widget build(BuildContext context) {
    const maxPressure = 200.0;
    const maxHeight = 140.0; // Как в пульсе

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bloodPressureData.every((data) => data['systolic'] == null)
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
                        children: bloodPressureData.map((data) {
                          final double columnHeight = data['systolic'] != null
                              ? (maxHeight - 20) * (data['systolic'] / maxPressure).clamp(0.0, 1.0)
                              : 10.0;
                          return SizedBox(
                            width: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: columnHeight,
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(159, 25, 242, 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      data['systolic'] != null
                                          ? '${data['systolic'].toInt()}/${data['diastolic'].toInt()}'
                                          : '',
                                      style: const TextStyle(
                                        color: Color.fromRGBO(242, 25, 141, 1),
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