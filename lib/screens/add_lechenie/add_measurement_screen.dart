import 'package:flutter/material.dart';
import 'measurement_settings_screen.dart';

class AddMeasurementScreen extends StatelessWidget {
  final String userId;
  final int courseId;

  const AddMeasurementScreen({
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
        title: const Text('Добавить измерение'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите тип измерения',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildMeasurementOption(
              context,
              'Кровяное давление',
              () => _navigateToSettingsScreen(context, 'Кровяное давление'),
            ),
            const SizedBox(height: 16),
            _buildMeasurementOption(
              context,
              'Пульс',
              () => _navigateToSettingsScreen(context, 'Пульс'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementOption(
      BuildContext context, String title, VoidCallback onTap) {
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
        onTap: onTap,
      ),
    );
  }

  void _navigateToSettingsScreen(BuildContext context, String measurementType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeasurementSettingsScreen(
          userId: userId,
          courseId: courseId,
          measurementType: measurementType,
        ),
      ),
    );
  }
}
