import 'package:flutter/material.dart';

class HealthSyncInstructionScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const HealthSyncInstructionScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка браслета'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Чтобы получать данные о шагах и пульсе с Mi Band, выполните следующие шаги:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('1. Откройте приложение Mi Fitness.'),
            const Text('2. Перейдите в Настройки → Данные → Экспорт данных.'),
            const Text(
                '3. Включите синхронизацию с Health Connect (Android) или HealthKit (iOS).'),
            const Text(
                '4. Подтвердите разрешения для передачи шагов и пульса.'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Продолжить'),
            ),
          ],
        ),
      ),
    );
  }
}
