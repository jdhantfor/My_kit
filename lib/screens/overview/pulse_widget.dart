import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_aptechka/screens/database_service.dart';

class PulseWidget extends StatefulWidget {
  final String userId;
  final String? requesterId;
  final String accessType;

  const PulseWidget({
    super.key,
    required this.userId,
    this.requesterId,
    required this.accessType,
  });

  @override
  State<PulseWidget> createState() => PulseWidgetState();
}

class PulseWidgetState extends State<PulseWidget> {
  List<Map<String, dynamic>> pulseData = [];
  bool isLoading = true;

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
      final requesterId = widget.requesterId ?? widget.userId;
      if (widget.userId == requesterId) {
        // Для текущего пользователя используем локальную базу
        final data = await DatabaseService.getPulseData(widget.userId);
        setState(() {
          pulseData = _prepareWeeklyData(data);
          isLoading = false;
        });
      } else {
        // Для семьи запрашиваем данные с сервера
        final response = await http.get(
          Uri.parse('http://62.113.37.96:5002/api/sync?uid=${widget.userId}&requester_id=$requesterId'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final pulse = (data['data']['pulse_data'] as List? ?? []).cast<Map<String, dynamic>>();
          setState(() {
            pulseData = _prepareWeeklyData(pulse);
            isLoading = false;
          });
        } else {
          throw Exception('Ошибка сервера: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Ошибка загрузки данных пульса: $e');
      setState(() {
        pulseData = [];
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
      double? avgValue;
      if (dayData.isNotEmpty) {
        final total = dayData.map((d) => d['value'] as num).reduce((a, b) => a + b);
        avgValue = total / dayData.length;
      }
      weeklyData.add({
        'date': date,
        'value': avgValue,
        'dayOfWeek': dayNames[weekDays[i].weekday - 1],
      });
    }
    return weeklyData;
  }

  void refresh() {
    _loadPulseData();
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
                              ? (maxHeight - 20) * (data['value'] / maxPulse).clamp(0.0, 1.0)
                              : 10.0;
                          return SizedBox(
                            width: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: columnHeight,
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(242, 25, 141, 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      data['value'] != null ? '${data['value'].toInt()}' : '',
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