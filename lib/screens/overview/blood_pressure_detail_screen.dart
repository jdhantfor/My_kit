import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/overview/add_blood_pressure.dart';
import 'package:fl_chart/fl_chart.dart';

class BloodPressureDetailScreen extends StatefulWidget {
  final String userId;

  const BloodPressureDetailScreen({super.key, required this.userId});

  @override
  _BloodPressureDetailScreenState createState() =>
      _BloodPressureDetailScreenState();
}

class _BloodPressureDetailScreenState extends State<BloodPressureDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTab = 'Дни';

  List<Map<String, dynamic>> graphData = [];
  Map<String, dynamic> summaryData = {
    'systolic': {'min': 0, 'avg': 0, 'max': 0},
    'diastolic': {'min': 0, 'avg': 0, 'max': 0}
  };
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

    final data = await DatabaseService.getBloodPressureDataForPeriod(
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

      if (intervalData.isNotEmpty) {
        final systolicValues = intervalData
            .map((d) => d['systolic'] as int?)
            .where((v) => v != null)
            .cast<int>()
            .toList();
        final diastolicValues = intervalData
            .map((d) => d['diastolic'] as int?)
            .where((v) => v != null)
            .cast<int>()
            .toList();

        final minSystolic = systolicValues.isNotEmpty
            ? systolicValues.reduce((a, b) => a < b ? a : b)
            : null;
        final maxSystolic = systolicValues.isNotEmpty
            ? systolicValues.reduce((a, b) => a > b ? a : b)
            : null;
        final minDiastolic = diastolicValues.isNotEmpty
            ? diastolicValues.reduce((a, b) => a < b ? a : b)
            : null;
        final maxDiastolic = diastolicValues.isNotEmpty
            ? diastolicValues.reduce((a, b) => a > b ? a : b)
            : null;

        preparedData.add({
          'date': dateStr,
          'minSystolic': minSystolic?.toDouble(),
          'maxSystolic': maxSystolic?.toDouble(),
          'minDiastolic': minDiastolic?.toDouble(),
          'maxDiastolic': maxDiastolic?.toDouble(),
          'label': label,
        });
      } else {
        preparedData.add({
          'date': dateStr,
          'minSystolic': null,
          'maxSystolic': null,
          'minDiastolic': null,
          'maxDiastolic': null,
          'label': label,
        });
      }
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

    final data = await DatabaseService.getBloodPressureSummary(
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

    final data = await DatabaseService.getBloodPressureComments(
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
        title: const Text('Кровяное давление',
            style: TextStyle(color: Colors.black)),
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
                onPressed: () {
                  _showAddBloodPressureDialog();
                },
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
    const double minY = 0;
    const double maxY = 200; // Максимальная высота
    const double interval = 40;

    int labelStep;
    double barWidth;
    switch (_selectedTab) {
      case 'Дни':
        labelStep = 4; // Метки каждые 4 часа
        barWidth = 10;
        break;
      case 'Недели':
        labelStep = 1; // Метки для каждого дня
        barWidth = 20;
        break;
      case 'Месяцы':
        labelStep = 7; // Метки каждые 7 дней
        barWidth = 15;
        break;
      default:
        labelStep = 1;
        barWidth = 20;
    }

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
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value % interval == 0 && value >= minY && value <= maxY) {
                    return Text(
                      value.toInt().toString(),
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
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          barGroups: graphData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            double minSystolic = data['minSystolic'] ?? minY;
            double maxSystolic = data['maxSystolic'] ?? minY;
            double minDiastolic = data['minDiastolic'] ?? minY;
            double maxDiastolic = data['maxDiastolic'] ?? minY;

            // Ограничение максимального значения до 200
            if (maxSystolic > maxY) maxSystolic = maxY;
            if (minSystolic > maxY) minSystolic = maxY;
            if (maxDiastolic > maxY) maxDiastolic = maxY;
            if (minDiastolic > maxY) minDiastolic = maxY;

            if (minSystolic == maxSystolic && minSystolic != minY)
              maxSystolic += 1;
            if (minDiastolic == maxDiastolic && minDiastolic != minY)
              maxDiastolic += 1;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: maxSystolic,
                  fromY: minSystolic,
                  color: const Color.fromRGBO(159, 25, 242, 1), // Систолическое
                  width: barWidth / 2,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                BarChartRodData(
                  toY: maxDiastolic,
                  fromY: minDiastolic,
                  color:
                      const Color.fromRGBO(159, 25, 242, 0.5), // Диастолическое
                  width: barWidth / 2,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ],
              barsSpace: 2, // Пространство между барами одного интервала
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
                  color: Color.fromRGBO(159, 25, 242, 1),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Систолическое', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(159, 25, 242, 0.5),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Диастолическое', style: TextStyle(fontSize: 14)),
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
                      'Среднее',
                      summaryData['systolic']['avg'],
                      summaryData['diastolic']['avg'],
                      const Color.fromRGBO(159, 25, 242, 1)),
                  const SizedBox(width: 32),
                  _buildSummaryItem(
                      'Максимальное',
                      summaryData['systolic']['max'],
                      summaryData['diastolic']['max'],
                      const Color.fromRGBO(159, 25, 242, 1)),
                  const SizedBox(width: 32),
                  _buildSummaryItem(
                      'Минимальное',
                      summaryData['systolic']['min'],
                      summaryData['diastolic']['min'],
                      const Color.fromRGBO(159, 25, 242, 1)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
      String label, int? systolic, int? diastolic, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${systolic ?? 0}/${diastolic ?? 0}',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(width: 4),
            const Text(
              'мм рт.ст.',
              style: TextStyle(
                  fontSize: 12, color: Color.fromRGBO(159, 25, 242, 1)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
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
                      color: const Color.fromRGBO(159, 25, 242, 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${comment['systolic'] ?? 0}/${comment['diastolic'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(159, 25, 242, 1),
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

  void _showAddBloodPressureDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: AddBloodPressure(
            title: 'Добавить измерение',
            userId: widget.userId,
          ),
        );
      },
    ).then((_) => _loadData());
  }
}
