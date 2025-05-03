import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../add_lechenie/add_treatment_screen.dart';
import '../user_provider.dart';
import '/styles.dart'; // Импортируем стили

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context).userId;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/tablet.png',
            width: 210,
            height: 210,
          ),
          const SizedBox(height: 1),
          Text(
            'На данном экране будет\nрасписание напоминаний',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: const Color(0xFF0B102B), // Цвет из текущего стиля
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Добавьте первое напоминание о приеме\nпрепарата, привычку или процедуру',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280), // Цвет из текущего стиля
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: userId != null
                ? () => _navigateToAddTreatmentScreen(context, userId)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  AppColors.primaryBlue, // Цвет кнопки из AppColors
              foregroundColor: Colors.white,
              elevation: 0, // Убираем тень (согласно AppTheme)
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24.0), // Скругление из AppTheme
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 14), // Отступы
              minimumSize: const Size(0,
                  48), // Убираем минимальную ширину, чтобы кнопка подстраивалась под текст
            ),
            child: Text(
              'Добавить',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white, // Цвет текста кнопки
                    fontWeight: FontWeight.w600, // Commissioner W600
                    fontSize: 16, // Размер 16
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTreatmentScreen(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTreatmentScreen(userId: userId),
      ),
    );
  }
}
