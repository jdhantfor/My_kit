import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/overview/add_pulse.dart';

class PulseDetailScreen extends StatefulWidget {
  final String userId;

  const PulseDetailScreen({super.key, required this.userId});

  @override
  _PulseDetailScreenState createState() => _PulseDetailScreenState();
}

class _PulseDetailScreenState extends State<PulseDetailScreen> {
  int _selectedPeriod = 0; // 0 - Дни, 1 - Недели, 2 - Месяцы
  List<Map<String, dynamic>> _pulseData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPulseData();
  }

  Future<void> _loadPulseData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await DatabaseService.getPulseData(widget.userId);
      setState(() {
        _pulseData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Пульс', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: _showAddPulseDialog,
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildPulseList(),
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

  Widget _buildPulseList() {
    if (_pulseData.isEmpty) {
      return const Center(child: Text('Нет данных о пульсе'));
    }
    return ListView.builder(
      itemCount: _pulseData.length,
      itemBuilder: (context, index) {
        final item = _pulseData[index];
        return ListTile(
          title: Text('${item['pulse']} уд/мин'),
          subtitle: Text(item['date']),
          trailing: item['systolic'] != null && item['diastolic'] != null
              ? Text('${item['systolic']}/${item['diastolic']} мм рт. ст.')
              : null,
        );
      },
    );
  }

  void _showAddPulseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddPulse(
            title: 'Добавить измерение',
            userId: widget.userId,
          ),
        );
      },
    ).then((_) => _loadPulseData());
  }
}
