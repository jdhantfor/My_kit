import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/overview/add_steps.dart';

class StepsDetailScreen extends StatefulWidget {
  final String userId;

  const StepsDetailScreen({super.key, required this.userId});

  @override
  _StepsDetailScreenState createState() => _StepsDetailScreenState();
}

class _StepsDetailScreenState extends State<StepsDetailScreen> {
  int _selectedPeriod = 0; // 0 - Дни, 1 - Недели, 2 - Месяцы
  List<Map<String, dynamic>> _stepsData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStepsData();
  }

  Future<void> _loadStepsData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await DatabaseService.getStepsData(widget.userId);
      setState(() {
        _stepsData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading steps data: $e');
      setState(() {
        _isLoading = false;
      });
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
        title: const Text('Шаги', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed: _showAddStepsDialog,
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
                : _buildStepsList(),
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

  Widget _buildStepsList() {
    if (_stepsData.isEmpty) {
      return const Center(child: Text('Нет данных о шагах'));
    }
    return ListView.builder(
      itemCount: _stepsData.length,
      itemBuilder: (context, index) {
        final item = _stepsData[index];
        return ListTile(
          title: Text('${item['count']} шагов'),
          subtitle: Text(item['date']),
        );
      },
    );
  }

  void _showAddStepsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: AddSteps(
            title: 'Добавить шаги',
            userId: widget.userId,
          ),
        );
      },
    ).then((_) => _loadStepsData());
  }
}
