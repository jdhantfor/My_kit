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
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите тип действия или привычки',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildActionOrHabitOption(context, 'Зарядка', 'Зарядка'),
            const SizedBox(height: 16),
            _buildActionOrHabitOption(context, 'Питьё воды', 'Питьё воды'),
            const SizedBox(height: 16),
            _buildActionOrHabitOption(context, 'Тренировка', 'Тренировка'),
            const SizedBox(height: 16),
            _buildActionOrHabitOption(context, 'Прогулка', 'Прогулка'),
            const SizedBox(height: 16),
            _buildActionOrHabitOption(context, 'Бег', 'Бег'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
// Переход к экрану добавления пользовательской привычки
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActionOrHabitSettingsScreen(
                      userId: userId,
                      courseId: courseId,
                      actionType: 'custom',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF197FF2),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Добавить свою привычку'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOrHabitOption(
      BuildContext context, String title, String actionType) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
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
      ),
    );
  }
}
