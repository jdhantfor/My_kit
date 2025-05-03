import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:my_aptechka/screens/database_service.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:my_aptechka/styles.dart';
import 'package:my_aptechka/screens/profile_screen.dart'; // Импортируем ProfileScreen

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isLoading = false;
  String _selectedPlan = 'yearly'; // По умолчанию выбираем "Ежегодно"

  Future<void> _activatePromo() async {
    final promoCode = _promoController.text.trim();
    if (promoCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите промокод')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID пользователя не указан')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://62.113.37.96:5002/activate_promo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'promo_code': promoCode,
        }),
      );

      if (response.statusCode == 200) {
        // Обновляем локальную базу
        await DatabaseService.updateUserDetails(userId, subscribe: 1);
        // Обновляем UserProvider
        userProvider.setSubscribe(true);
        // Синхронизируем с сервером
        await DatabaseService().syncWithServer(userId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Подписка активирована')),
        );
        Navigator.pop(context);
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Ошибка активации')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Фоновое изображение
          Positioned.fill(
            child: Image.asset(
              'assets/background_sub.jpg',
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
          ),
          // Основной контент
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 100, left: 4, bottom: 24, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Центрируем логотип и иконку
                  children: [
                    // Логотип
                    SvgPicture.asset(
                      'assets/logo_white.svg',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 24),
                    SvgPicture.asset(
                      'assets/sub.svg',
                      width: 30,
                      height: 30,
                    ),
                    const SizedBox(height: 24),
                    // Заголовок
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Выберите формат оплаты семейной подписки',
                        style: TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Вариант "Ежегодно"
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlan = 'yearly';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: _selectedPlan == 'yearly'
                              ? Border.all(color: Colors.white, width: 1)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ежегодно',
                                  style: TextStyle(
                                    fontFamily: 'Commissioner',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      '124 ₽/месяц',
                                      style: TextStyle(
                                        fontFamily: 'Commissioner',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        '-32%',
                                        style: TextStyle(
                                          fontFamily: 'Commissioner',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '1490 ₽/год',
                                  style: TextStyle(
                                    fontFamily: 'Commissioner',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedPlan == 'yearly'
                                    ? Colors.white
                                    : Colors.transparent,
                                border: Border.all(color: Colors.white),
                              ),
                              child: _selectedPlan == 'yearly'
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.primaryBlue,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Вариант "Ежемесячно"
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlan = 'monthly';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: _selectedPlan == 'monthly'
                              ? Border.all(color: Colors.white, width: 1)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ежемесячно',
                                  style: TextStyle(
                                    fontFamily: 'Commissioner',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '149 ₽/месяц',
                                  style: TextStyle(
                                    fontFamily: 'Commissioner',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedPlan == 'monthly'
                                    ? Colors.white
                                    : Colors.transparent,
                                border: Border.all(color: Colors.white),
                              ),
                              child: _selectedPlan == 'monthly'
                                  ? const Icon(
                                      Icons.check,
                                      color: AppColors.primaryBlue,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Поле ввода промокода
                    TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: 'Введите промокод',
                        hintStyle: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Commissioner',
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Commissioner',
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Кнопка "Подключить"
                    ElevatedButton(
                      onPressed: _isLoading ? null : _activatePromo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: Size(MediaQuery.of(context).size.width - 32, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: AppColors.primaryBlue)
                          : Text(
                              'Подключить за ${_selectedPlan == 'yearly' ? '1490 ₽/год' : '149 ₽/месяц'}',
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Commissioner',
                              ),
                            ),
                    ),
                    const SizedBox(height:48),
                    // Ссылка "Сможете отменить в любой момент"
                    Center(
                      child: Text(
                        'Сможете отменить в любой момент',
                        style: TextStyle(
                          fontFamily: 'Commissioner',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Кнопка "Назад" в левом верхнем углу (размещаем в конце списка children)
          Positioned(
            top: 16,
            left: 8,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  print('Back button pressed'); // Для отладки
                  // Переходим на ProfileScreen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8.0), // Увеличиваем область нажатия
                  child: SvgPicture.asset(
                    'assets/arrow_back.svg',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}