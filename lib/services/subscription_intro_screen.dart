import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_aptechka/services/subscription_screen.dart';
import 'package:my_aptechka/styles.dart';
import 'package:my_aptechka/screens/profile_screen.dart'; // Импортируем ProfileScreen

class SubscriptionIntroScreen extends StatefulWidget {
  const SubscriptionIntroScreen({Key? key}) : super(key: key);

  @override
  _SubscriptionIntroScreenState createState() => _SubscriptionIntroScreenState();
}

class _SubscriptionIntroScreenState extends State<SubscriptionIntroScreen> {
  // Переменная для отслеживания выбранной подписки (визуально)
  String? _selectedSubscription;

  @override
  void initState() {
    super.initState();
    // По умолчанию выбираем "Первичная" (можно изменить на "Семейная")
    _selectedSubscription = 'Первичная';
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
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 52),
                    // Заголовок
                    const Text(
                      'Войдите в возможности с подпиской',
                      style: TextStyle(
                        fontFamily: 'Commissioner',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Первичная подписка в контейнере
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSubscription = 'Первичная';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: _selectedSubscription == 'Первичная'
                              ? Border.all(color: Colors.white, width: 1)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Первичная',
                                  style: TextStyle(
                                    fontFamily: 'Commissioner',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(context, 'Подключение фитнес-браслета и мониторинг здоровья', 'assets/braslet1.svg'),
                                _buildFeatureItem(context, 'Точные настройки напоминаний', 'assets/nastr.svg'),
                                _buildFeatureItem(context, 'Дневник симптомов', 'assets/dnevnik.svg'),
                                _buildFeatureItem(context, 'Общее хранение и восстановление данных', 'assets/cloud.svg'),
                                _buildFeatureItem(context, 'Здоровье о здоровье', 'assets/ads.svg'),
                              ],
                            ),
                            if (_selectedSubscription == 'Первичная')
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: AppColors.primaryBlue,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Семейная подписка в контейнере
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSubscription = 'Семейная';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: _selectedSubscription == 'Семейная'
                              ? Border.all(color: Colors.white, width: 1)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Семейная',
                                  style: TextStyle(
                                    fontFamily: 'Commissioner',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFeatureItem(context, 'Подключение фитнес-браслета и мониторинг здоровья', 'assets/braslet1.svg'),
                                _buildFeatureItem(context, 'Точные настройки напоминаний', 'assets/nastr.svg'),
                                _buildFeatureItem(context, 'Дневник симптомов', 'assets/dnevnik.svg'),
                                _buildFeatureItem(context, 'Общее хранение и восстановление данных', 'assets/cloud.svg'),
                                _buildFeatureItem(context, 'Здоровье о здоровье', 'assets/ads.svg'),
                                _buildFeatureItem(context, 'Отсутствие рекламы', 'assets/famaly1.svg'),
                                _buildFeatureItem(context, 'Доступ для родственников', 'assets/nitifi.svg'),
                              ],
                            ),
                            if (_selectedSubscription == 'Семейная')
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: AppColors.primaryBlue,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Кнопка "Продолжить"
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
       
                       
                      ),
                      child: const Text(
                        'Продолжить',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // Кнопка "Назад" в левом верхнем углу (размещаем в конце списка children, чтобы быть на верхнем слое)
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

  // Виджет для отображения пункта возможности
  Widget _buildFeatureItem(BuildContext context, String title, String iconPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}