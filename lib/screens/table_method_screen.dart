import 'package:flutter/material.dart';
import 'table_time_screen.dart';

class TableMethodScreen extends StatefulWidget {
  final String name;
  final String userId;
  final int courseId;

  const TableMethodScreen({
    super.key,
    required this.name,
    required this.userId,
    required this.courseId,
  });

  @override
  _TableMethodScreenState createState() => _TableMethodScreenState();
}

class _TableMethodScreenState extends State<TableMethodScreen> {
  String? _selectedUnit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color.fromARGB(255, 17, 13, 29)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Единица измерения препарата',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 54, 37, 37),
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.separated(
                itemCount: _measurementUnits.length,
                itemBuilder: (context, index) {
                  final unit = _measurementUnits[index];
                  return ListTile(
                    title: Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0B102B),
                      ),
                    ),
                    trailing: _selectedUnit == unit
                        ? const Icon(
                            Icons.check,
                            color: Color(0xFF197FF2),
                            size: 24,
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF0B102B),
                            size: 24,
                          ),
                    onTap: () {
                      setState(() {
                        _selectedUnit = unit;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TableTimeScreen(
                            name: widget.name,
                            unit: _selectedUnit!,
                            userId: widget.userId,
                            courseId: widget.courseId,
                          ),
                        ),
                      );
                    },
                  );
                },
                separatorBuilder: (context, index) => const Divider(
                  color: Color(0xFFE0E0E0),
                  thickness: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _measurementUnits = [
    'Таблетки',
    'Капсулы',
    'Миллилитры (мл)',
    'Миллиграммы (мг)',
    'Граммы (г)',
    'Капли',
    'Дозы',
    'Ампулы',
    'Международные единицы (МЕ)',
    'Чайные ложки (ч.л.)',
    'Столовые ложки (ст.л.)',
    'Флаконы',
    'Применения',
  ];
}
