import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_aptechka/screens/database_service.dart';

class BloodPressureWidget extends StatefulWidget {
  final String userId;
  final String? requesterId;
  final String accessType;

  const BloodPressureWidget({
    super.key,
    required this.userId,
    this.requesterId,
    required this.accessType,
  });

  @override
  State<BloodPressureWidget> createState() => BloodPressureWidgetState();
}

class BloodPressureWidgetState extends State<BloodPressureWidget> {
  List<Map<String, dynamic>> bloodPressureData = [];
  bool isLoading = true;

  bool get hasData => !bloodPressureData.every((data) => data['systolic'] == null);

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
      final requesterId = widget.requesterId ?? widget.userId;
      if (widget.userId == requesterId) {
        // Для текущего пользователя используем локальную базу
        final data = await DatabaseService.getBloodPressureData(widget.userId);
        setState(() {
          bloodPressureData = _prepareWeeklyData(data);
          isLoading = false;
        });
      } else {
        // Для семьи запрашиваем данные с сервера
        final response = await http.get(
          Uri.parse('http://62.113.37.96:5002/api/sync?uid=${widget.userId}&requester_id=$requesterId'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final bpData = (data['data']['blood_pressure_data'] as List? ?? []).cast<Map<String, dynamic>>();
          setState(() {
            bloodPressureData = _prepareWeeklyData(bpData);
            isLoading = false;
          });
        } else {
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Ошибка загрузки данных давления: $e');
      setState(() {
        bloodPressureData = [];
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
        final avgSystolic = dayData.map((d) => d['systolic'] as num).reduce((a, b) => a + b) / dayData.length;
        final avgDiastolic = dayData.map((d) => d['diastolic'] as num).reduce((a, b) => a + b) / dayData.length;
        weeklyData.add({
          'date': date,
          'systolic': avgSystolic.clamp(0, 200),
          'diastolic': avgDiastolic.clamp(0, 200),
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
    const maxHeight = 140.0;

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
                                        color: Color.fromRGBO(159, 25, 242, 1),
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