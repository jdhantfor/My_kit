import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_aptechka/screens/barcodes_screen.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'add_measurement_screen.dart';
import 'add_action_or_habit_screen.dart';

class AddLechenieItemsScreen extends StatelessWidget {
  final int courseId;
  final String userId;

  const AddLechenieItemsScreen({
    super.key,
    required this.courseId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(4),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Выберите, что хотите\nдобавить в курс лечения',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          _buildBox(
            child: Column(
              children: [
                _buildListTile(
                  icon: 'assets/priem.svg',
                  title: 'Приём препарата',
                  subtitle: 'Таблетки, капли или др',
                  context: context,
                  onTap: () => _showAddReminderBottomSheet(context),
                ),
                _buildDivider(),
                _buildListTile(
                  icon: 'assets/izmerenie_blue.svg',
                  title: 'Измерение',
                  subtitle: 'Пульс, артериальное давление или др',
                  context: context,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMeasurementScreen(
                          userId: userId,
                          courseId: courseId,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildListTile(
                  icon: 'assets/deistvie_blue.svg',
                  title: 'Действие или привычка',
                  subtitle: 'Зарядка, питьё воды или др.',
                  context: context,
                  onTap: () {
                    // Логика для добавления действия или привычки
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddActionOrHabitScreen(
                          userId: userId,
                          courseId: courseId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReminderBottomSheet(BuildContext context) async {
    final unassignedReminders = await DatabaseService.getRemindersByDate(
      userId,
      DateTime.now(), // Любая дата, так как мы ищем непривязанные напоминания
    );
    if (unassignedReminders.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24), // Закругление сверху
          ),
        ),
        backgroundColor: Colors.white, // Белый фон
        elevation: 0, // Убираем тень
        builder: (context) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4), // Отступы по бокам
            child: _buildExistingRemindersBottomSheet(unassignedReminders),
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodesScreen(
            userId: userId,
            courseId: courseId,
          ),
        ),
      );
    }
  }

  Widget _buildExistingRemindersBottomSheet(
      List<Map<String, dynamic>> unassignedReminders) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8), // Отступы по бокам
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // Закругление углов
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Выберите уже\nсуществующий приём\nили создайте новый',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.2, // Уменьшаем интервалы между строками
                  ),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unassignedReminders.length + 1,
              itemBuilder: (context, index) {
                if (index < unassignedReminders.length) {
                  final reminder = unassignedReminders[index];
                  return Column(
                    children: [
                      _buildListTileForBottomSheet(
                        title: reminder['name'],
                        iconPath: 'assets/priem_gray.svg',
                        onTap: () async {
                          Navigator.pop(context); // Закрываем bottom sheet
                          await DatabaseService.updateReminder(
                            Map.from(reminder)..['courseid'] = courseId,
                            userId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Напоминание добавлено в курс.'),
                            ),
                          );
                        },
                        reminder: reminder,
                      ),
                      Divider(
                        color: Colors.grey.withOpacity(0.5),
                        thickness: 1,
                        height: 1,
                        indent: 16, // Отступ слева
                        endIndent: 8, // Отступ справа
                      ),
                    ],
                  );
                } else {
                  // Пункт "Добавить новый приём"
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16.0),
                    leading: SvgPicture.asset(
                      'assets/priem_blue.svg',
                      width: 20,
                      height: 20,
                      color: Colors.blue,
                    ),
                    title: const Text(
                      'Добавить новый приём',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context); // Закрываем bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BarcodesScreen(
                            userId: userId,
                            courseId: courseId,
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildListTileForBottomSheet({
    required String title,
    required String iconPath,
    required VoidCallback onTap,
    required Map<String, dynamic> reminder,
  }) {
    // Сокращаем название до 25 символов с добавлением "..."
    final String truncatedTitle =
        title.length > 25 ? '${title.substring(0, 25)}...' : title;
    // Вычисляем оставшиеся дни
    final DateTime? startDate = reminder['startDate'] != null
        ? DateTime.tryParse(reminder['startDate'])
        : null;
    final DateTime? endDate = reminder['endDate'] != null
        ? DateTime.tryParse(reminder['endDate'])
        : null;
    // Проверяем, что даты существуют
    final int totalDays = startDate != null && endDate != null
        ? endDate.difference(startDate).inDays
        : 0;
    final int remainingDays =
        endDate != null ? endDate.difference(DateTime.now()).inDays : 0;
    // Форматируем даты, если они существуют
    final String formattedStartDate = startDate != null
        ? '${startDate.day} ${_getMonthName(startDate.month)}'
        : 'Не указано';
    final String formattedEndDate = endDate != null
        ? '${endDate.day} ${_getMonthName(endDate.month)}'
        : 'Не указано';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхняя строка: Иконка + Название + Стрелка вперед
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Левая часть: Иконка + Название
              Row(
                children: [
                  SvgPicture.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 12), // Отступ между иконкой и текстом
                  Text(
                    truncatedTitle, // Используем сокращенное название
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0B102B),
                    ),
                  ),
                ],
              ),
              // Правая часть: Стрелка вперед
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8), // Отступ между верхней и нижней строкой
          // Нижняя строка: Оставшиеся дни + Даты
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Левый текст: Осталось дней
              Text(
                remainingDays > 0
                    ? 'Осталось $remainingDays дней из $totalDays'
                    : 'Завершено',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              // Правый текст: Даты
              Text(
                '$formattedStartDate – $formattedEndDate',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    final List<String> months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return months[month - 1];
  }

  Widget _buildBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Divider(
        color: Colors.grey.withOpacity(0.5),
        thickness: 1,
        height: 1,
      ),
    );
  }

  Widget _buildListTile({
    required String icon,
    required String title,
    required String subtitle,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: SvgPicture.asset(
        icon,
        width: 48,
        height: 48,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0B102B),
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
