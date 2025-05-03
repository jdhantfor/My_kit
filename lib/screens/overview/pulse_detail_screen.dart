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

class _PulseDetailScreenState extends State<PulseDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTab = 'Дни';

  List<Map<String, dynamic>> graphData = [];
  Map<String, dynamic> summaryData = {'min': 0, 'avg': 0, 'max': 0};
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
        final values = intervalData.map((d) => d['value'] as int).toList();
        final minValue = values.reduce((a, b) => a < b ? a : b);
        final maxValue = values.reduce((a, b) => a > b ? a : b);
        preparedData.add({
          'date': dateStr,
          'minValue': minValue.toDouble(),
          'maxValue': maxValue.toDouble(),
          'label': label,
        });
      } else {
        preparedData.add({
          'date': dateStr,
          'minValue': null,
          'maxValue': null,
          'label': label,
        });
      }
    }

    print('Итоговые подготовленные данные: $preparedData');
    return preparedData;
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

    final data = await DatabaseService.getPulseDataForPeriod(
        widget.userId, startDate, endDate, _selectedTab);
    print('Полученные данные из базы: $data');

    final preparedData = _prepareData(data, _selectedTab, _selectedDate);
    print('Подготовленные данные для графика: $preparedData');

    setState(() {
      graphData = preparedData;
    });
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

    final data = await DatabaseService.getPulseSummary(
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
        startDate = DateFormat('yyyy-MM-dd').format(weekStart);
        endDate = DateFormat('yyyy-MM-dd').format(weekEnd);
        break;
      case 'Месяцы':
        startDate = DateFormat('yyyy-MM-01').format(_selectedDate);
        endDate = DateFormat('yyyy-MM-dd')
            .format(DateTime(_selectedDate.year, _selectedDate.month + 1, 0));
        break;
      default:
        return;
    }
    print('Извлекаем комментарии для периода: $_selectedTab');
    print('StartDate: $startDate');
    print('EndDate: $endDate');

    final data = await DatabaseService.getPulseComments(
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
            color: _selectedTab == tab
                ? Colors.blue
                : const Color.fromARGB(0, 96, 96, 96),
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
          _buildSummary(),
          _buildComments(),
        ],
      ),
    );
  }

  Widget _buildGraph() {
    const double minY = 0; // Фиксированное минимальное значение
    const double maxY = 200; // Фиксированное максимальное значение
    const double interval = 40; // Интервал между метками

    int labelStep;
    double barWidth;
    switch (_selectedTab) {
      case 'Дни':
        labelStep = 4; // Метки каждые 4 часа
        barWidth = 10; // Уже бары для 24 часов
        break;
      case 'Недели':
        labelStep = 1; // Метки для каждого дня
        barWidth = 20;
        break;
      case 'Месяцы':
        labelStep = 7; // Метки каждые 7 дней
        barWidth = 15; // Чуть уже для 31 дня
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
            double minValue = data['minValue'] ?? minY;
            double maxValue = data['maxValue'] ?? minY;

            if (minValue == maxValue && minValue != minY) {
              maxValue += 1;
            }

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: maxValue,
                  fromY: minValue,
                  color: const Color.fromARGB(226, 242, 25, 141),
                  width: barWidth,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Выравнивание по левому краю
      children: [
        const Padding(
          padding:
              EdgeInsets.only(left: 16.0, bottom: 8.0), // Отступы для заголовка
          child: Text(
            'Сводка дня',
            style: TextStyle(
              color: Colors.grey, // Серый заголовок
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(4.0), // Отступы для контейнера
          padding: const EdgeInsets.all(16.0), // Внутренние отступы
          decoration: BoxDecoration(
            color: Colors.white, // Белый фон
            borderRadius: BorderRadius.circular(24), // Закругление 24
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // Тень для эффекта
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Выравнивание по левому краю
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Выравнивание по левому краю
                children: [
                  _buildSummaryItem(summaryData['min'], 'Минимальный', 'пульс'),
                  const SizedBox(width: 32), // Отступ между элементами
                  _buildSummaryItem(summaryData['avg'], 'Средний', 'пульс'),
                  const SizedBox(width: 32), // Отступ между элементами
                  _buildSummaryItem(
                      summaryData['max'], 'Максимальный', 'пульс'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(int? value, String label, String unit) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Выравнивание по левому краю
      children: [
        Row(
          mainAxisSize: MainAxisSize.min, // Минимальный размер строки
          crossAxisAlignment:
              CrossAxisAlignment.baseline, // Выравнивание по базовой линии
          textBaseline: TextBaseline.alphabetic, // Базовая линия для текста
          children: [
            Text(
              value?.toString() ?? '0', // Обработка null значения
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(242, 25, 141, 1), // Цвет как на скриншоте
              ),
            ),
            const SizedBox(width: 4), // Отступ между цифрой и единицей
            const Text(
              'уд/мин',
              style: TextStyle(
                fontSize: 12,
                color: Color.fromRGBO(242, 25, 141, 1), // Один цвет с цифрой
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: Colors.grey), // Серый подзаголовок
        ),
        Text(
          unit,
          style: const TextStyle(
              fontSize: 12, color: Colors.grey), // Серый подзаголовок
        ),
      ],
    );
  }

  Widget _buildComments() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Выравнивание по левому краю
      children: [
        const Padding(
          padding:
              EdgeInsets.only(left: 16.0, bottom: 8.0), // Отступы для заголовка
          child: Text(
            'Комментарии',
            style: TextStyle(
              color: Colors.grey, // Серый заголовок
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin:
              const EdgeInsets.symmetric(horizontal: 4.0), // Внешние отступы
          decoration: BoxDecoration(
            color: Colors.white, // Белый фон
            borderRadius: BorderRadius.circular(24), // Закругление 24
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // Тень для эффекта
              ),
            ],
          ),
          child: comments.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Нет комментариев',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : _buildGroupedComments(),
        ),
      ],
    );
  }

  Widget _buildGroupedComments() {
    // Группировка комментариев по дате
    Map<String, List<Map<String, dynamic>>> groupedComments = {};
    for (var comment in comments) {
      String dateStr = comment['date'];
      if (dateStr != null) {
        DateTime dateTime = DateTime.parse(dateStr);
        String dateKey = DateFormat('d MMMM', 'ru')
            .format(dateTime); // Формат даты как "25 ноября"
        if (groupedComments[dateKey] == null) {
          groupedComments[dateKey] = [];
        }
        groupedComments[dateKey]!.add(comment);
      }
    }

    // Показываем группировку только для "Недели" и "Месяцы"
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
                // Центрируем контейнер с датой
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.grey
                        .withOpacity(0.1), // Серый контейнер для даты
                    borderRadius: BorderRadius.circular(8), // Закругление
                  ),
                  child: Text(
                    entry.key, // Дата как "25 ноября"
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0, // Отступы по горизонтали 16
                vertical: 8.0, // Вертикальные отступы для каждого комментария
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(
                          242, 25, 141, 0.08), // Фон для цифры
                      borderRadius:
                          BorderRadius.circular(8), // Закругление бокса
                    ),
                    child: Text(
                      '${comment['value']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(242, 25, 141, 1), // Цвет цифры
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Отступ между боксом и текстом
                  Expanded(
                    child: Text(
                      comment['comment'],
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
            // Добавляем разделитель, если это не последний элемент
            if (index < commentsList.length - 1)
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16.0), // Отступы для линии
                height: 1, // Толщина линии
                color: Colors.grey.withOpacity(0.3), // Тонкая серая линия
              ),
          ],
        );
      }).toList(),
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
