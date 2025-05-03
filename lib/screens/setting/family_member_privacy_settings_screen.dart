import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:my_aptechka/styles.dart';
import 'package:provider/provider.dart';

class FamilyMemberPrivacySettingsScreen extends StatefulWidget {
  final String memberId; // ID члена семьи
  final String memberEmail; // Email члена семьи для отображения

  const FamilyMemberPrivacySettingsScreen({
    super.key,
    required this.memberId,
    required this.memberEmail,
  });

  @override
  _FamilyMemberPrivacySettingsScreenState createState() =>
      _FamilyMemberPrivacySettingsScreenState();
}

class _FamilyMemberPrivacySettingsScreenState
    extends State<FamilyMemberPrivacySettingsScreen> {
  // Переменные для переключателей
  bool _allowViewMedicalHistory = false;
  bool _allowViewMedicalIndicators = false;
  bool _allowViewPrescriptions = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings(); // Загружаем текущие настройки приватности
  }

  // Загрузка текущих настроек приватности с сервера
  Future<void> _loadPrivacySettings() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID пользователя не указан')),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'http://62.113.37.96:5002/privacy_settings?user_id=$userId&member_id=${widget.memberId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allowViewMedicalHistory = data['allow_view_medical_history'] ?? false;
          _allowViewMedicalIndicators =
              data['allow_view_medical_indicators'] ?? false;
          _allowViewPrescriptions = data['allow_view_prescriptions'] ?? false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Ошибка загрузки настроек: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка соединения с сервером')),
      );
    }
  }

  // Сохранение настроек приватности на сервере
  Future<void> _savePrivacySettings() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID пользователя не указан')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://62.113.37.96:5002/privacy_settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'member_id': widget.memberId,
          'allow_view_medical_history': _allowViewMedicalHistory,
          'allow_view_medical_indicators': _allowViewMedicalIndicators,
          'allow_view_prescriptions': _allowViewPrescriptions,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки сохранены')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Ошибка сохранения настроек: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка соединения с сервером')),
      );
    }
  }

  Future<void> _removeFamilyMember() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final userId = userProvider.userId;

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID пользователя не указан')),
    );
    return;
  }

  try {
    final response = await http.delete(
      Uri.parse(
          'http://62.113.37.96:5002/family_members?user_id=$userId&member_id=${widget.memberId}'),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true); // Возвращаем true, чтобы указать, что член семьи удалён
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.memberEmail} исключён из семьи')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка исключения из семьи: ${response.statusCode}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ошибка соединения с сервером')),
    );
  }
}

  // Показ диалога подтверждения исключения 
  void _confirmRemoveFamilyMember() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Исключить из семьи',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B102B),
            ),
          ),
          content: Text(
            'Вы уверены, что хотите исключить ${widget.memberEmail} из семьи?',
            style: const TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Отмена',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрываем диалог
                _removeFamilyMember(); // Вызываем удаление
              },
              child: const Text(
                'Исключить',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0B102B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Настройки ${widget.memberEmail}',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Разрешить пользователю просмотр медицинской истории
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Разрешить пользователю просмотр моей медицинской истории',
                    style: TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0B102B),
                    ),
                  ),
                ),
                Switch(
                  value: _allowViewMedicalHistory,
                  onChanged: (value) {
                    setState(() {
                      _allowViewMedicalHistory = value;
                    });
                    _savePrivacySettings();
                  },
                  activeColor: AppColors.primaryBlue,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE5E7EB),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Просмотр показателей здоровья
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Просмотр показателей здоровья (пульс, давление и т.д.)',
                    style: TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0B102B),
                    ),
                  ),
                ),
                Switch(
                  value: _allowViewMedicalIndicators,
                  onChanged: (value) {
                    setState(() {
                      _allowViewMedicalIndicators = value;
                    });
                    _savePrivacySettings();
                  },
                  activeColor: AppColors.primaryBlue,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE5E7EB),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Просмотр рецептов
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Просмотр рецептов',
                    style: TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF0B102B),
                    ),
                  ),
                ),
                Switch(
                  value: _allowViewPrescriptions,
                  onChanged: (value) {
                    setState(() {
                      _allowViewPrescriptions = value;
                    });
                    _savePrivacySettings();
                  },
                  activeColor: AppColors.primaryBlue,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFE5E7EB),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Кнопка "Исключить из семьи"
            Center(
              child: ElevatedButton(
                onPressed: _confirmRemoveFamilyMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2), // Цвет фона
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: const Text(
                  'Исключить из семьи',
                  style: TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}