import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_aptechka/screens/add_lechenie/add_lechenie.dart';
import 'package:my_aptechka/screens/barcodes_screen.dart';
import 'package:my_aptechka/screens/add_lechenie/add_measurement_screen.dart';
import 'add_action_or_habit_screen.dart';

class AddTreatmentScreen extends StatelessWidget {
  final String userId;
  const AddTreatmentScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: const EdgeInsets.fromLTRB(4, 16, 16, 0),
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8), // Соответствие стилю
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Выберите, что хотите\nдобавить',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: const Color(0xFF0B102B),
                  ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 24),
          _buildBox(
            child: _buildListTile(
              icon: 'assets/lechenie.svg',
              title: 'Курс лечения',
              subtitle: 'Препараты, измерения и действия',
              context: context,
            ),
          ),
          const SizedBox(height: 16),
          _buildBox(
            child: Column(
              children: [
                _buildListTile(
                  icon: 'assets/priem.svg',
                  title: 'Приём препарата',
                  subtitle: 'Таблетки, капли или др',
                  context: context,
                ),
                _buildDivider(),
                _buildListTile(
                  icon: 'assets/izmerenie.svg',
                  title: 'Измерение',
                  subtitle: 'Пульс, артериальное давление или др',
                  context: context,
                ),
                _buildDivider(),
                _buildListTile(
                  icon: 'assets/deistvie.svg',
                  title: 'Действие или привычка',
                  subtitle: 'Зарядка, питьё воды или др.',
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildListTile({
    required String icon,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: SvgPicture.asset(
        icon,
        width: 40,
        height: 40,
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
      onTap: () async {
        if (title == 'Курс лечения') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddLechenieScreen(userId: userId),
            ),
          );
        } else if (title == 'Приём препарата') {
          {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BarcodesScreen(
                  userId: userId,
                  courseId: -1,
                ),
              ),
            );
          }
        } else if (title == 'Измерение') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMeasurementScreen(
                userId: userId,
                courseId: -1,
              ),
            ),
          );
        } else if (title == 'Действие или привычка') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddActionOrHabitScreen(
                userId: userId,
                courseId: -1,
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: Colors.grey[300],
        thickness: 1,
        height: 1,
      ),
    );
  }
}
