import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/overview/add_pulse.dart';
import 'package:fl_chart/fl_chart.dart';

class PulseDetailScreen extends StatefulWidget {
  final String userId;

  const PulseDetailScreen({super.key, required this.userId});

  @override
  _PulseDetailScreenState createState() => _PulseDetailScreenState();
}

class _PulseDetailScreenState extends State<PulseDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String _selectedTab = 'Дни';

  List<Map<String, dynamic>> graphData = [];
  Map<String, dynamic> summaryData = {'min': 0, 'avg': 0, 'max': 0};
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  int _selectedPeriod = 0;

  @override
void initState() {
  super.initState();
  _tabController = TabController(length: 3, vsync: this);
  _tabController.addListener(_handleTabChange);
  // Добавление тестовых данных
  DatabaseService.addPulseData('2024-02-27 08:00:00', 110, widget.userId, comment: 'Утро');
  DatabaseService.addPulseData('2024-02-27 12:00:00', 112, widget.userId, comment: 'Полдень');
  DatabaseService.addPulseData('2024-02-27 20:00:00', 192, widget.userId, comment: 'Вечер');
  _loadData();
}

  void _handleTabChange() {
    setState(() {
      _selectedTab = ['Дни', 'Недели', 'Месяцы'][_tabController.index];
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
  // Добавляем тестовые данные для 28 февраля 2025
  await DatabaseService.addPulseData('2025-02-28 08:00:00', 110, widget.userId, comment: 'Утро');
  await DatabaseService.addPulseData('2025-02-28 12:00:00', 112, widget.userId, comment: 'Полдень');
  await DatabaseService.addPulseData('2025-02-28 20:00:00', 192, widget.userId, comment: 'Вечер');
  
  // Загружаем данные для графика
  await _fetchGraphData();
    setState(() => isLoading = true);
    await _fetchGraphData();
    await _fetchSummaryData();
    await _fetchComments();
    setState(() => isLoading = false);
  }

 Future<void> _fetchGraphData() async {
  String startDate, endDate;
  switch (_selectedTab) {
    case 'Дни':
      startDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      endDate = startDate;
      break;
    case 'Недели':
      startDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      endDate = DateFormat('yyyy-MM-dd').format(_selectedDate.add(const Duration(days: 6)));
      break;
    case 'Месяцы':
      startDate = DateFormat('yyyy-MM-01').format(_selectedDate);
      endDate = DateFormat('yyyy-MM-dd').format(DateTime(_selectedDate.year, _selectedDate.month + 1, 0));
      break;
    default:
      return;
  }
  final data = await DatabaseService.getPulseDataForPeriod(widget.userId, startDate, endDate, _selectedTab);
  print('Fetched graph data in PulseDetailScreen: $data'); // Отладка полученных данных
  setState(() {
    graphData = data;
  });
}

  Future<void> _fetchSummaryData() async {
    String startDate, endDate;
    switch (_selectedTab) {
      case 'Дни':
        startDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
        endDate = startDate;
        break;
      case 'Недели':
        startDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd').format(_selectedDate.add(const Duration(days: 6)));
        break;
      case 'Месяцы':
        startDate = DateFormat('yyyy-MM-01').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd').format(DateTime(_selectedDate.year, _selectedDate.month + 1, 0));
        break;
      default:
        return;
    }
    final data = await DatabaseService.getPulseSummary(widget.userId, startDate, endDate);
    setState(() {
      summaryData = data;
    });
  }

  Future<void> _fetchComments() async {
    String startDate, endDate;
    switch (_selectedTab) {
      case 'Дни':
        startDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
        endDate = startDate;
        break;
      case 'Недели':
        startDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd').format(_selectedDate.add(const Duration(days: 6)));
        break;
      case 'Месяцы':
        startDate = DateFormat('yyyy-MM-01').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd').format(DateTime(_selectedDate.year, _selectedDate.month + 1, 0));
        break;
      default:
        return;
    }
    final data = await DatabaseService.getPulseComments(widget.userId, startDate, endDate);
    setState(() {
      comments = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Пульс'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPulseBottomSheet(context),
          ),
        ],
      ),
      body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          _buildPeriodButtons(),
          _buildDateNavigation(),
          Expanded(child: _buildContent()),
        ],
      
            ),
    );
  }
Widget _buildPeriodButtons() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildPeriodButton('День', 0),
          _buildPeriodButton('Неделя', 1),
          _buildPeriodButton('Месяц', 2),
        ],
      ),
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
        _loadData();
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
  Widget _buildDateNavigation() {
    String dateText;
    switch (_selectedTab) {
      case 'Дни':
        dateText = DateFormat('d MMMM', 'ru').format(_selectedDate);
        break;
      case 'Недели':
        DateTime weekEnd = _selectedDate.add(const Duration(days: 6));
        dateText = '${DateFormat('d MMMM', 'ru').format(_selectedDate)} – ${DateFormat('d MMMM', 'ru').format(weekEnd)}';
        break;
      case 'Месяцы':
        dateText = DateFormat('MMMM yyyy', 'ru').format(_selectedDate);
        break;
      default:
        dateText = '';
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedTab == 'Дни'
                    ? _selectedDate.subtract(const Duration(days: 1))
                    : _selectedTab == 'Недели'
                        ? _selectedDate.subtract(const Duration(days: 7))
                        : DateTime(_selectedDate.year, _selectedDate.month - 1);
              });
              _loadData();
            },
          ),
          Text(dateText, style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.arrow_right),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedTab == 'Дни'
                    ? _selectedDate.add(const Duration(days: 1))
                    : _selectedTab == 'Недели'
                        ? _selectedDate.add(const Duration(days: 7))
                        : DateTime(_selectedDate.year, _selectedDate.month + 1);
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildGraph(),
          _buildSummary(),
          _buildComments(),
        ],
      ),
    );
  }

  Widget _buildGraph() {
  // Пример данных: замените на свои реальные данные
  List<Map<String, dynamic>> graphData = [
    {'min': 110, 'max': 123}, // 00:00-01:00: диапазон 110-123
    {'min': 120, 'max': 120}, // 01:00-02:00: одно значение 120
    // Добавьте данные для остальных часов (всего 24 интервала)
  ];

  return Container(
    height: 200,
    padding: const EdgeInsets.all(16),
    child: BarChart(
      BarChartData(
        minY: 0, // Минимальное значение по оси Y
        maxY: 200, // Максимальное значение по оси Y
        titlesData: FlTitlesData(
          // Отключаем метки слева
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          // Настраиваем метки справа
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 40, // Шаг меток: 0, 40, 80, 120, 160, 200
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                );
              },
            ),
          ),
          // Настраиваем ось X (время)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                final labels = ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '00:00'];
                if (index % 4 == 0 && index <= 24) {
                  int labelIndex = (index / 4).floor();
                  if (labelIndex < labels.length) {
                    return Text(
                      labels[labelIndex],
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        // Настраиваем сетку
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 40,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        // Создаём столбики для каждого часа
        barGroups: List.generate(24, (index) {
          if (index < graphData.length && graphData[index] != null) {
            double minValue = graphData[index]['min']?.toDouble() ?? 0;
            double maxValue = graphData[index]['max']?.toDouble() ?? 0;
            if (minValue == maxValue) {
              // Если одно значение (например, 120), рисуем линию
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: maxValue,
                    fromY: maxValue, // fromY = toY для одной линии
                    width: 4,
                    color: const Color.fromRGBO(242, 25, 141, 0.8), // Розовый цвет
                  ),
                ],
              );
            } else {
              // Если диапазон (например, 110-123), рисуем столбик
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: maxValue,
                    fromY: minValue,
                    width: 4,
                    color: const Color.fromRGBO(242, 25, 141, 0.8),
                  ),
                ],
              );
            }
          } else {
            // Если данных нет, пустой столбик
            return BarChartGroupData(x: index, barRods: []);
          }
        }),
      ),
    ),
  );
}

Widget _buildSummary() {
  return Column(
    children: [
      const Text('Сводка дня', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSummaryItem('мин', summaryData['min'], 'минимальный'),
          _buildSummaryItem('средн', summaryData['avg'], 'средний'),
          _buildSummaryItem('макс', summaryData['max'], 'максимальный'),
        ],
      ),
    ],
  );
}

Widget _buildSummaryItem(String label, int value, String subLabel) {
  return Column(
    children: [
      Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromRGBO(242, 25, 141, 1))),
      const Text('уд/мин', style: TextStyle(fontSize: 12, color: Colors.grey)),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(subLabel, style: const TextStyle(fontSize: 12, color: Color.fromRGBO(242, 25, 141, 1))),
    ],
  );
}

  Widget _buildComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Комментарии', style: TextStyle(color: Colors.grey)),
        ),
        if (comments.isEmpty)
          const Text('Нет комментариев', style: TextStyle(color: Colors.grey))
        else
          ...comments.map((comment) => Card(
                color: const Color.fromRGBO(242, 25, 141, 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${comment['value']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromRGBO(242, 25, 141, 1))),
                      Expanded(child: Text(comment['comment'], style: const TextStyle(fontSize: 16))),
                      Text(DateFormat('HH:mm').format(DateTime.parse(comment['date'])), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  void _showAddPulseBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPulse(title: 'Пульс', userId: widget.userId),
    ).then((_) => _loadData());
  }
}