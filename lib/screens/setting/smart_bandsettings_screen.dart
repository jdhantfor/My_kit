import 'package:flutter/material.dart';

class SmartBandSettingsScreen extends StatelessWidget {
  const SmartBandSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Симуляция состояния подключения браслета (замени на реальную логику)
    bool isBandConnected = false; // По умолчанию браслет не подключен

    if (!isBandConnected) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Настройки браслета'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/braslet.png', // Иконка слева
                            width: 24,
                            height: 24,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Добавить браслет',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'с помощью Bluetooth',
                                style: TextStyle(
                                  color: Color(0xFF197FF2), // Голубой текст
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Настройки браслета'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettingItem(
                context,
                'Xiaomi Smart Band 9',
                subtitle: 'подключен',
                isEnabled: true,
              ),
              const SizedBox(height: 16),
              _buildSettingItem(
                context,
                'Пульс',
                isEnabled: true,
              ),
              _buildSettingItem(
                context,
                'Шаги',
                isEnabled: true,
              ),
              _buildSettingItem(
                context,
                'Кровяное давление',
                isEnabled: true,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Логика удаления браслета
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: Size(MediaQuery.of(context).size.width - 40, 50),
                ),
                child: const Text(
                  'Удалить браслет',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildSettingItem(BuildContext context, String title,
      {String? subtitle, bool isEnabled = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            Switch(
              value: isEnabled,
              onChanged: (value) {
                // Логика изменения состояния переключателя
              },
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
