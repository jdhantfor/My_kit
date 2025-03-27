import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/barcodes_screen.dart';

class AddActionBottomSheet extends StatelessWidget {
  final String userId;
  final int courseId;

  const AddActionBottomSheet({
    super.key,
    required this.userId,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Выберите тип напоминания',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        _buildListTile(
          icon: 'assets/priem.png',
          title: 'Приём препарата',
          subtitle: 'Таблетки, капли или др',
          context: context,
          onTap: () {
            Navigator.pop(context); // Закрываем bottom sheet
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BarcodesScreen(
                        userId: userId,
                        courseId: courseId,
                      )),
            );
          },
        ),
        _buildDivider(),
        _buildListTile(
          icon: 'assets/izmerenie.png',
          title: 'Измерение',
          subtitle: 'Пульс, артериальное давление или др',
          context: context,
          onTap: () {
            // Добавьте здесь логику для обработки нажатия
            Navigator.pop(context);
          },
        ),
        _buildDivider(),
        _buildListTile(
          icon: 'assets/deistvie.png',
          title: 'Действие или привычка',
          subtitle: 'Зарядка, питьё воды или др.',
          context: context,
          onTap: () {
            // Добавьте здесь логику для обработки нажатия
            Navigator.pop(context);
          },
        ),
      ],
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
      leading: Image.asset(icon, width: 44, height: 44),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[200],
    );
  }
}
