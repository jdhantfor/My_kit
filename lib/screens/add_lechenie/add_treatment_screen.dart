import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_aptechka/screens/add_lechenie/add_lechenie.dart';
import 'package:my_aptechka/screens/barcodes_screen.dart';
import 'package:my_aptechka/screens/add_lechenie/add_measurement_screen.dart';
import 'add_action_or_habit_screen.dart'; // Импортируем новый экран

class AddTreatmentScreen extends StatelessWidget {
  final String userId;
  const AddTreatmentScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text(
              'Выберите, что хотите\nдобавить',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 24),
          _buildBox(
            child: _buildListTile(
              icon: 'assets/lechenie.png',
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
                  icon: 'assets/priem.png',
                  title: 'Приём препарата',
                  subtitle: 'Таблетки, капли или др',
                  context: context,
                ),
                _buildDivider(),
                _buildListTile(
                  icon: 'assets/izmerenie.png',
                  title: 'Измерение',
                  subtitle: 'Пульс, артериальное давление или др',
                  context: context,
                ),
                _buildDivider(),
                _buildListTile(
                  icon: 'assets/deistvie.png',
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
      leading: Image.asset(icon, width: 40, height: 40),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18, // Увеличили размер шрифта
          fontWeight: FontWeight.w500, // Сделали шрифт жирнее
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        if (title == 'Курс лечения') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddLechenieScreen(userId: userId),
            ),
          );
        } else if (title == 'Приём препарата') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarcodesScreen(
                userId: userId,
                courseId:
                    -1, // Используем -1 как значение по умолчанию для courseId
              ),
            ),
          );
        } else if (title == 'Измерение') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMeasurementScreen(
                userId: userId,
                courseId:
                    -1, // Используем -1 как значение по умолчанию для courseId
              ),
            ),
          );
        } else if (title == 'Действие или привычка') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddActionOrHabitScreen(
                userId: userId,
                courseId:
                    -1, // Используем -1 как значение по умолчанию для courseId
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(
        color: Colors.grey.withOpacity(0.5),
        thickness: 1,
        height: 1,
      ),
    );
  }
}
