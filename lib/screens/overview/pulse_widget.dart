import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart'; // Убедитесь, что путь к файлу правильный

class PulseWidget extends StatefulWidget {
  final String userId;

  const PulseWidget({super.key, required this.userId});

  @override
  _PulseWidgetState createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> {
  List<Map<String, dynamic>> pulseData = [];
  bool isLoading = true;

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
      // Загрузка данных из базы данных
      final data = await DatabaseService.getPulseData(widget.userId);
      setState(() {
        pulseData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading pulse data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxPulse = 150.0;
    const maxHeight = 120.0;

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
                if (pulseData.isNotEmpty) ...[
                  const Text(
                    'Средний показатель за 7 дней',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: maxHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: pulseData.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final Map<String, dynamic> data = entry.value;
                        final double columnHeight =
                            (maxHeight * (data['value'] / maxPulse))
                                .clamp(0.0, maxHeight);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 2,
                              right: index == pulseData.length - 1 ? 0 : 2,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: columnHeight,
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromRGBO(242, 25, 141, 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '${data['value']}',
                                        style: const TextStyle(
                                          color:
                                              Color.fromRGBO(242, 25, 141, 1),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: pulseData
                        .map((data) => Expanded(
                              child: Center(
                                child: Text(data['date'],
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ))
                        .toList(),
                  ),
                ] else ...[
                  const Text(
                    'Нет данных о пульсе',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ],
            ),
    );
  }
}
