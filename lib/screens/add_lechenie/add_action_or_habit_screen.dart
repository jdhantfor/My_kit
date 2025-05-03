import 'package:flutter/material.dart';
import 'action_or_habit_settings_screen.dart';

class AddActionOrHabitScreen extends StatelessWidget {
  final String userId;
  final int courseId;

  const AddActionOrHabitScreen({
    super.key,
    required this.userId,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Добавить привычку'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Контейнер для списка привычек с закруглением 24
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildActionOrHabitOption(context, 'Зарядка', 'Зарядка'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                  ),
                  _buildActionOrHabitOption(
                      context, 'Питьё воды', 'Питьё воды'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                  ),
                  _buildActionOrHabitOption(
                      context, 'Тренировка', 'Тренировка'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                  ),
                  _buildActionOrHabitOption(context, 'Прогулка', 'Прогулка'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                  ),
                  _buildActionOrHabitOption(context, 'Бег', 'Бег'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Кнопка "Добавить свою привычку" с закруглением 24 и без обводки
            ElevatedButton(
              onPressed: () async {
                final customHabitName = await _showCustomHabitDialog(context);
                if (customHabitName != null && customHabitName.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActionOrHabitSettingsScreen(
                        userId: userId,
                        courseId: courseId,
                        actionType: 'custom',
                        customName: customHabitName,
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF197FF2),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0), // Закругление 24
                ),
                elevation: 0, // Убираем тень
                side: BorderSide.none, // Убираем обводку
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Color(0xFF197FF2)),
                  SizedBox(width: 8),
                  Text('Добавить свою привычку',
                      style: TextStyle(color: Color(0xFF197FF2))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOrHabitOption(
      BuildContext context, String title, String actionType) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 18)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActionOrHabitSettingsScreen(
              userId: userId,
              courseId: courseId,
              actionType: actionType,
            ),
          ),
        );
      },
    );
  }

  Future<String?> _showCustomHabitDialog(BuildContext context) async {
    final TextEditingController _controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Введите название привычки'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Например, Чтение'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_controller.text);
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );
  }
}
