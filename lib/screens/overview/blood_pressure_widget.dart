import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';

class BloodPressureWidget extends StatefulWidget {
  final String userId;

  const BloodPressureWidget({super.key, required this.userId});

  @override
  _BloodPressureWidgetState createState() => _BloodPressureWidgetState();
}

class _BloodPressureWidgetState extends State<BloodPressureWidget> {
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
        bloodPressureData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке данных: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bloodPressureData.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Средний показатель за 7 дней',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final data = index < bloodPressureData.length
                          ? bloodPressureData[index]
                          : null;
                      return Column(
                        children: [
                          Text(_getDayOfWeek(index),
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Container(
                            width: 30,
                            height: 60,
                            color: const Color.fromRGBO(242, 25, 141, 0.08),
                            child: Center(
                              child: data != null
                                  ? Text(
                                      '${data['systolic']}/${data['diastolic']}',
                                      style: const TextStyle(
                                        color: Color.fromRGBO(242, 25, 141, 1),
                                        fontSize: 10,
                                      ),
                                    )
                                  : const Text('-',
                                      style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  const Text('Нет данных о кровяном давлении',
                      style: TextStyle(color: Colors.grey)),
                ],
                const SizedBox(height: 16)
              ],
            ),
    );
  }

  String _getDayOfWeek(int index) {
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final today = DateTime.now().weekday - 1;
    return days[(today - index + 7) % 7];
  }
}
