import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/overview/add_blood_pressure.dart';

class BloodPressureDetailScreen extends StatefulWidget {
  final String userId;

  const BloodPressureDetailScreen({super.key, required this.userId});

  @override
  _BloodPressureDetailScreenState createState() =>
      _BloodPressureDetailScreenState();
}

class _BloodPressureDetailScreenState extends State<BloodPressureDetailScreen> {
  int _selectedPeriod = 0; // 0 - Дни, 1 - Недели, 2 - Месяцы
  List<Map<String, dynamic>> _bloodPressureData = [];

  @override
  void initState() {
    super.initState();
    _loadBloodPressureData();
  }

  Future<void> _loadBloodPressureData() async {
    try {
      final data = await DatabaseService.getBloodPressureData(widget.userId);
      setState(() {
        _bloodPressureData = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке данных: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Кровяное давление',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: () {
                _showAddBloodPressureDialog();
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                _buildPeriodButton('Дни', 0),
                _buildPeriodButton('Недели', 1),
                _buildPeriodButton('Месяцы', 2),
              ],
            ),
          ),
          Expanded(
            child: _buildBloodPressureList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedPeriod == index ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _selectedPeriod == index ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBloodPressureList() {
    return ListView.builder(
      itemCount: _bloodPressureData.length,
      itemBuilder: (context, index) {
        final item = _bloodPressureData[index];
        return ListTile(
          title: Text('${item['systolic']}/${item['diastolic']} мм рт. ст.'),
          subtitle: Text(item['date']),
          trailing:
              item['pulse'] != null ? Text('Пульс: ${item['pulse']}') : null,
        );
      },
    );
  }

  void _showAddBloodPressureDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddBloodPressure(
            title: 'Добавить измерение',
            userId: widget.userId,
          ),
        );
      },
    ).then((_) => _loadBloodPressureData());
  }
}
