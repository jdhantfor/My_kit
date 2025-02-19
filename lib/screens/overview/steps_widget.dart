import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';

class StepsWidget extends StatefulWidget {
  final String userId;

  const StepsWidget({super.key, required this.userId});

  @override
  _StepsWidgetState createState() => _StepsWidgetState();
}

class _StepsWidgetState extends State<StepsWidget> {
  List<Map<String, dynamic>> stepsData = [];

  @override
  void initState() {
    super.initState();
    _loadStepsData();
  }

  Future<void> _loadStepsData() async {
    final data = await DatabaseService.getStepsData(widget.userId);
    setState(() {
      stepsData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stepsData.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Количество шагов за 7 дней',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final data = index < stepsData.length ? stepsData[index] : null;
                final maxSteps = stepsData.fold(0,
                    (max, item) => item['count'] > max ? item['count'] : max);
                return Column(
                  children: [
                    Text(_getDayOfWeek(index),
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 30,
                      height: 60,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 30,
                            height: data != null
                                ? (data['count'] / maxSteps) * 60
                                : 0,
                            color: const Color.fromRGBO(242, 25, 141, 0.08),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: data != null
                                ? Text(
                                    '${(data['count'] / 1000).toStringAsFixed(1)}k',
                                    style: const TextStyle(
                                      color: Color.fromRGBO(242, 25, 141, 1),
                                      fontSize: 10,
                                    ),
                                  )
                                : const Text('-',
                                    style: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text('Нет данных о шагах',
                style: TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 16),
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
