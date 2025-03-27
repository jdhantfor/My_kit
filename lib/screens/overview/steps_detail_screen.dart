import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/overview/add_steps.dart';
import 'package:fl_chart/fl_chart.dart';

class StepsDetailScreen extends StatefulWidget {
  final String userId;

  const StepsDetailScreen({super.key, required this.userId});

  @override
  _StepsDetailScreenState createState() => _StepsDetailScreenState();
}

class _StepsDetailScreenState extends State<StepsDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTab = 'Дни';

  List<Map<String, dynamic>> graphData = [];
  Map<String, dynamic> summaryData = {'total': 0, 'average': 0};
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
        startDate = DateFormat('yyyy-MM-dd 00:00:00').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd 23:59:59').format(_selectedDate);
        break;
      case 'Недели':
        DateTime weekStart =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        DateTime weekEnd = weekStart.add(const Duration(days: 6));
        startDate = DateFormat('yyyy-MM-dd 00:00:00').format(weekStart);
        endDate = DateFormat('yyyy-MM-dd 23:59:59').format(weekEnd);
        break;
      case 'Месяцы':
        startDate = DateFormat('yyyy-MM-01 00:00:00').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd 23:59:59')
            .format(DateTime(_selectedDate.year, _selectedDate.month + 1, 0));
        break;
      default:
        return;
    }
    print('Извлекаем данные для графика:');
    print('Период: $_selectedTab');
    print('StartDate: $startDate');
    print('EndDate: $endDate');

    final data = await DatabaseService.getStepsDataForPeriod(
        widget.userId, startDate, endDate, _selectedTab);
    print('Полученные данные из базы: $data');

    final preparedData = _prepareData(data, _selectedTab, _selectedDate);
    print('Подготовленные данные для графика: $preparedData');

    setState(() {
      graphData = preparedData;
    });
  }

  List<Map<String, dynamic>> _prepareData(
      List<Map<String, dynamic>> data, String period, DateTime selectedDate) {
    List<Map<String, dynamic>> preparedData = [];
    DateTime startDate;
    int intervals;

    print('Подготовка данных для периода: $period');
    print('Входные данные: $data');

    switch (period) {
      case 'Дни':
        startDate =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        intervals = 24;
        break;
      case 'Недели':
        startDate =
            selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        intervals = 7;
        break;
      case 'Месяцы':
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        intervals = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
        break;
      default:
        print('Неизвестный период: $period');
        return preparedData;
    }

    for (int i = 0; i < intervals; i++) {
      DateTime currentDate = period == 'Дни'
          ? startDate.add(Duration(hours: i))
          : startDate.add(Duration(days: i));
      String label = period == 'Дни'
          ? DateFormat('HH:mm').format(currentDate)
          : DateFormat('dd/MM').format(currentDate);
      String dateStr = DateFormat('yyyy-MM-dd HH:mm').format(currentDate);

      final intervalData = data.where((item) {
        if (item['date'] == null) return false;
        final itemDate = DateTime.parse(item['date']);
        if (period == 'Дни') {
          return itemDate.hour == currentDate.hour &&
              itemDate.day == currentDate.day &&
              itemDate.month == currentDate.month &&
              itemDate.year == currentDate.year;
        } else {
          return itemDate.day == currentDate.day &&
              itemDate.month == currentDate.month &&
              itemDate.year == currentDate.year;
        }
      }).toList();

      print('Фильтрованные данные для интервала $dateStr: $intervalData');

      final totalSteps = intervalData.isNotEmpty
          ? intervalData.map((d) => d['count'] as int).reduce((a, b) => a + b)
          : 0;

      preparedData.add({
        'date': dateStr,
        'value': totalSteps.toDouble(),
        'label': label,
      });
    }

    print('Итоговые подготовленные данные: $preparedData');
    return preparedData;
  }

  Future<void> _fetchSummaryData() async {
    String startDate, endDate;
    switch (_selectedTab) {
      case 'Дни':
        startDate = DateFormat('yyyy-MM-dd 00:00:00').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd 23:59:59').format(_selectedDate);
        break;
      case 'Недели':
        DateTime weekStart =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        DateTime weekEnd = weekStart.add(const Duration(days: 6));
        startDate = DateFormat('yyyy-MM-dd 00:00:00').format(weekStart);
        endDate = DateFormat('yyyy-MM-dd 23:59:59').format(weekEnd);
        break;
      case 'Месяцы':
        startDate = DateFormat('yyyy-MM-01 00:00:00').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd 23:59:59')
            .format(DateTime(_selectedDate.year, _selectedDate.month + 1, 0));
        break;
      default:
        return;
    }
    print('Извлекаем сводку данных для периода: $_selectedTab');
    print('StartDate: $startDate');
    print('EndDate: $endDate');

    final data = await DatabaseService.getStepsSummary(
        widget.userId, startDate, endDate);
    print('Сводные данные из базы: $data');

    setState(() {
      summaryData = data;
    });
  }

  Future<void> _fetchComments() async {
    String startDate, endDate;
    switch (_selectedTab) {
      case 'Дни':
        startDate = DateFormat('yyyy-MM-dd 00:00:00').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd 23:59:59').format(_selectedDate);
        break;
      case 'Недели':
        DateTime weekStart =
            _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        DateTime weekEnd = weekStart.add(const Duration(days: 6));
        startDate = DateFormat('yyyy-MM-dd 00:00:00').format(weekStart);
        endDate = DateFormat('yyyy-MM-dd 23:59:59').format(weekEnd);
        break;
      case 'Месяцы':
        startDate = DateFormat('yyyy-MM-01 00:00:00').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd 23:59:59')
            .format(DateTime(_selectedDate.year, _selectedDate.month + 1, 0));
        break;
      default:
        return;
    }
    print('Извлекаем комментарии для периода: $_selectedTab');
    print('StartDate: $startDate');
    print('EndDate: $endDate');

    final data = await DatabaseService.getStepsComments(
        widget.userId, startDate, endDate);
    print('Полученные комментарии из базы: $data');

    setState(() {
      comments = data;
    });
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
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: _showAddStepsDialog,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildPeriodButton('Дни', 'Дни'),
            _buildPeriodButton('Недели', 'Недели'),
            _buildPeriodButton('Месяцы', 'Месяцы'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String title, String tab) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tab;
          });
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _selectedTab == tab ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: _selectedTab == tab
                  ? Colors.white
                  : const Color.fromARGB(255, 89, 89, 89),
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
        DateTime weekEnd =
            _selectedDate.add(Duration(days: 6 - (_selectedDate.weekday - 1)));
        dateText =
            '${DateFormat('d MMMM', 'ru').format(_selectedDate.subtract(Duration(days: _selectedDate.weekday - 1)))} – ${DateFormat('d MMMM', 'ru').format(weekEnd)}';
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
            icon: const Icon(Icons.arrow_back_ios_rounded),
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
          Text(dateText,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
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
          _buildLegend(),
          _buildSummary(),
          _buildComments(),
        ],
      ),
    );
  }

  Widget _buildGraph() {
    const double intervalBase = 5; // Количество интервалов между 6 метками
    double maxY;
    int labelStep;
    double barWidth;
    switch (_selectedTab) {
      case 'Дни':
        maxY = 2000;
        labelStep = 4; // Метки каждые 4 часа
        barWidth = 5; // Уменьшено с 10 до 5
        break;
      case 'Недели':
        maxY = 20000;
        labelStep = 1; // Метки для каждого дня
        barWidth = 10; // Уменьшено с 20 до 10
        break;
      case 'Месяцы':
        maxY = 60000;
        labelStep = 7; // Метки каждые 7 дней
        barWidth = 7.5; // Уменьшено с 15 до 7.5
        break;
      default:
        maxY = 2000;
        labelStep = 1;
        barWidth = 5; // Уменьшено с 20 до 5
    }

    // Вычисляем шаг для 6 меток (0, шаг, 2*шаг, ..., maxY)
    double interval = maxY / intervalBase;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= graphData.length)
                    return const Text('');
                  if (index % labelStep == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        graphData[index]['label'],
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval, // Устанавливаем равный шаг
                getTitlesWidget: (value, meta) {
                  // Показываем только 6 меток (0, шаг, 2*шаг, 3*шаг, 4*шаг, maxY)
                  double normalizedValue =
                      (value / interval).round() * interval;
                  if (normalizedValue >= 0 &&
                      normalizedValue <= maxY &&
                      (normalizedValue % interval == 0 ||
                          normalizedValue == maxY)) {
                    return Text(
                      normalizedValue.toInt().toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval, // Синхронизируем сетку с метками
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY,
          barGroups: graphData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            double value = data['value'] ?? 0;

            // Ограничение максимального значения до maxY
            if (value > maxY) value = maxY;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  fromY: 0,
                  color: const Color.fromRGBO(242, 162, 25, 1),
                  width: barWidth,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(242, 162, 25, 1),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Шаги', style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            _selectedTab == 'Дни'
                ? 'Сводка дня'
                : _selectedTab == 'Недели'
                    ? 'Сводка недели'
                    : 'Сводка месяца',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(4.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildSummaryItem(
                      summaryData['total'].toString(), 'Всего', 'шагов'),
                  const SizedBox(width: 32),
                  _buildSummaryItem(summaryData['average'].toStringAsFixed(0),
                      'Среднее', 'шагов'),
                  const SizedBox(width: 32),
                  _buildSummaryItem(
                      '-', 'Цель', 'шагов'), // Плейсхолдер для третьей колонки
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String value, String label, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(242, 162, 25, 1)),
            ),
            const SizedBox(width: 4),
            const Text(
              'шагов',
              style: TextStyle(
                  fontSize: 12, color: Color.fromRGBO(242, 162, 25, 1)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Комментарии',
            style: TextStyle(
                color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: comments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Нет комментариев',
                      style: TextStyle(color: Colors.grey)),
                )
              : _buildGroupedComments(),
        ),
      ],
    );
  }

  Widget _buildGroupedComments() {
    Map<String, List<Map<String, dynamic>>> groupedComments = {};
    for (var comment in comments) {
      String dateStr = comment['date'];
      if (dateStr != null) {
        DateTime dateTime = DateTime.parse(dateStr);
        String dateKey = DateFormat('d MMMM', 'ru').format(dateTime);
        if (groupedComments[dateKey] == null) {
          groupedComments[dateKey] = [];
        }
        groupedComments[dateKey]!.add(comment);
      }
    }

    if (_selectedTab == 'Дни') {
      return Column(
        children: groupedComments.entries.map((entry) {
          return _buildCommentList(entry.value);
        }).toList(),
      );
    } else {
      return Column(
        children: groupedComments.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ),
              _buildCommentList(entry.value),
            ],
          );
        }).toList(),
      );
    }
  }

  Widget _buildCommentList(List<Map<String, dynamic>> commentsList) {
    return Column(
      children: commentsList.asMap().entries.map((entry) {
        final index = entry.key;
        final comment = entry.value;
        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(242, 162, 25, 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${comment['count']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(242, 162, 25, 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      comment['comment'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(DateTime.parse(comment['date'])),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (index < commentsList.length - 1)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                height: 1,
                color: Colors.grey.withOpacity(0.3),
              ),
          ],
        );
      }).toList(),
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
    ).then((_) => _loadData());
  }
}
