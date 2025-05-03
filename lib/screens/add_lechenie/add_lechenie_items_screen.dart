import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_aptechka/screens/barcodes_screen.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'add_measurement_screen.dart';
import 'add_action_or_habit_screen.dart';
import '../home_screen.dart'; 
import '/styles.dart';

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
          padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
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
                  icon: 'assets/izmerenie.svg',
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
                  icon: 'assets/deistvie.svg',
                  title: 'Действие или привычка',
                  subtitle: 'Зарядка, питьё воды или др.',
                  context: context,
                  onTap: () {
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

  void _showAddReminderBottomSheet(BuildContext parentContext) async {
    final databaseService = DatabaseService();
    final unassignedReminders = await databaseService.getRemindersByDate(
      userId,
      DateTime.now(),
    );

    if (unassignedReminders.isNotEmpty) {
      showModalBottomSheet(
        context: parentContext,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildExistingRemindersBottomSheet(
              context,
              parentContext, 
              unassignedReminders,
            ),
          );
        },
      );
    } else {
      Navigator.push(
        parentContext,
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
    BuildContext context,
    BuildContext parentContext, 
    List<Map<String, dynamic>> unassignedReminders,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: const Color(0xFF0B102B),
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
                      context: context,
                      parentContext: parentContext, 
                      title: reminder['name'],
                      iconPath: 'assets/priem_gray.svg',
                      onTap: () async {
                        Navigator.pop(context);
                        final databaseService = DatabaseService();
                        try {
                          await databaseService.updateReminder(
                            Map.from(reminder)..['courseid'] = courseId,
                            userId,
                          ); 
                          Navigator.pushAndRemoveUntil(
                            parentContext,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(
                                initialIndex: 1, 
                              ),
                            ),
                            (Route<dynamic> route) => false, 
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка при добавлении напоминания: $e'),
                            ),
                          );
                        }
                      },
                      reminder: reminder,
                    ),
                    Divider(
                      color: Colors.grey.withOpacity(0.5),
                      thickness: 1,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                  ],
                );
              } else {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  leading: SvgPicture.asset(
                    'assets/priem_blue.svg',
                    width: 20,
                    height: 20,
                  ),
                  title: Text(
                    'Добавить новый приём',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                  ),
                  trailing: SvgPicture.asset(
                    'assets/arrow_forward.svg',
                    width: 20,
                    height: 20,
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    Navigator.push(
                      parentContext,
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
    );
  }

  Widget _buildListTileForBottomSheet({
    required BuildContext context,
    required BuildContext parentContext, // Добавляем родительский context
    required String title,
    required String iconPath,
    required VoidCallback onTap,
    required Map<String, dynamic> reminder,
  }) {
    final String truncatedTitle =
        title.length > 25 ? '${title.substring(0, 25)}...' : title;
    final DateTime? startDate = reminder['startDate'] != null
        ? DateTime.tryParse(reminder['startDate'])
        : null;
    final DateTime? endDate = reminder['endDate'] != null
        ? DateTime.tryParse(reminder['endDate'])
        : null;
    final int totalDays = startDate != null && endDate != null
        ? endDate.difference(startDate).inDays
        : 0;
    final int remainingDays =
        endDate != null ? endDate.difference(DateTime.now()).inDays : 0;
    final String formattedStartDate = startDate != null
        ? '${startDate.day} ${_getMonthName(startDate.month)}'
        : 'Не указано';
    final String formattedEndDate = endDate != null
        ? '${endDate.day} ${_getMonthName(endDate.month)}'
        : 'Не указано';
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      iconPath,
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      truncatedTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF0B102B),
                          ),
                    ),
                  ],
                ),
                SvgPicture.asset(
                  'assets/arrow_forward.svg',
                  width: 20,
                  height: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  remainingDays > 0
                      ? 'Осталось $remainingDays дней из $totalDays'
                      : 'Завершено',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
                Text(
                  '$formattedStartDate – $formattedEndDate',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: SvgPicture.asset(
        icon,
        width: 48,
        height: 48,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF0B102B),
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
      ),
      trailing: SvgPicture.asset(
        'assets/arrow_forward.svg',
        width: 20,
        height: 20,
      ),
      onTap: onTap,
    );
  }
}