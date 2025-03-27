import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../styles.dart'; // Импортируем стили
import 'overview/pulse_widget.dart';
import 'overview/blood_pressure_widget.dart';
import 'overview/steps_widget.dart';
import 'overview/pulse_detail_screen.dart';
import 'overview/blood_pressure_detail_screen.dart';
import 'overview/steps_detail_screen.dart';
import 'overview/add_pulse.dart';
import 'overview/add_blood_pressure.dart';
import 'overview/add_steps.dart';
import 'overview/documents_screen.dart';
import 'user_provider.dart';
import 'dart:math' as math;

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class FamilyMember {
  final String id;
  final String name;
  final String email;
  String? avatarUrl;

  FamilyMember({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });
}

class _OverviewScreenState extends State<OverviewScreen> {
  final GlobalKey<PulseWidgetState> _pulseKey = GlobalKey();
  final GlobalKey<BloodPressureWidgetState> _bloodPressureKey = GlobalKey();
  final GlobalKey<StepsWidgetState> _stepsKey = GlobalKey();
  int _selectedTab = 0;
  List<FamilyMember> familyMembers = [];
  FamilyMember? selectedMember;
  bool isFamilyListVisible = false;
  bool isLoading = true;

  // Настраиваемые отступы (копируем из предыдущих экранов)
  final double horizontalPadding = 16.0;
  final double appBarTopPadding = 40.0;
  final double iconSize = 32.0;
  final double appBarTitleSpacing = 8.0;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() => isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    final userEmail = userProvider.email;

    if (userId == null || userEmail == null) {
      print(
          'Ошибка: ID или email пользователя не указан. userId: $userId, userEmail: $userEmail');
      setState(() => isLoading = false);
      return;
    }

    // Добавляем текущего пользователя в список
    final currentUser = FamilyMember(
      id: userId,
      name: userProvider.name ?? 'Имя не указано',
      email: userEmail,
      avatarUrl: userProvider.avatarUrl,
    );

    // Загружаем членов семьи с сервера
    const int maxRetries = 5;
    const Duration timeoutDuration = Duration(seconds: 30);
    int attempt = 0;
    final client = http.Client();

    try {
      while (attempt < maxRetries) {
        try {
          final request = http.Request(
            'GET',
            Uri.parse(
                'http://62.113.37.96:5002/family_members?user_id=$userId'),
          )
            ..headers['Content-Type'] = 'application/json'
            ..headers['Connection'] =
                'close'; // Отключаем keep-alive на стороне клиента

          final streamedResponse =
              await client.send(request).timeout(timeoutDuration);
          final response = await http.Response.fromStream(streamedResponse);

          print('--- Отладка загрузки членов семьи ---');
          print('userId: $userId');
          print(
              'URL запроса: http://62.113.37.96:5002/family_members?user_id=$userId');
          print('Статус ответа: ${response.statusCode}');
          print('Тело ответа: ${response.body}');

          if (response.statusCode == 200) {
            final Map<String, dynamic> responseData = jsonDecode(response.body);
            final List<dynamic> familyData = responseData['members'] ?? [];
            print('Данные членов семьи (familyData): $familyData');

            final List<FamilyMember> members = familyData.map((data) {
              return FamilyMember(
                id: data['user_id']?.toString() ?? '',
                name: data['name']?.toString() ?? 'Имя не указано',
                email: data['email']?.toString() ?? '',
                avatarUrl: data['avatar_url']?.toString(),
              );
            }).toList();

            print('Список членов семьи после обработки (members): $members');

            setState(() {
              familyMembers = [currentUser, ...members];
              selectedMember =
                  currentUser; // По умолчанию выбираем текущего пользователя
              isLoading = false;
            });
            return; // Успешно загрузили данные, выходим из цикла
          } else {
            print(
                'Ошибка загрузки членов семьи: статус ${response.statusCode}');
            throw Exception('Ошибка сервера: ${response.statusCode}');
          }
        } catch (e) {
          attempt++;
          if (attempt == maxRetries) {
            print(
                'Ошибка при загрузке членов семьи после $maxRetries попыток: $e');
            setState(() {
              familyMembers = [currentUser];
              selectedMember = currentUser;
              isLoading = false;
            });
            return;
          }
          print(
              'Попытка $attempt/$maxRetries: Ошибка при загрузке членов семьи: $e. Повтор через 3 секунды...');
          await Future.delayed(Duration(seconds: 3));
        }
      }
    } finally {
      client.close(); // Закрываем клиент после всех попыток
    }
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Функция в разработке',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B102B),
            ),
          ),
          content: const Text(
            'Настройки приватности семьи скоро будут доступны!',
            style: TextStyle(
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
                'OK',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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
    final userId = Provider.of<UserProvider>(context).userId;
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Пожалуйста, войдите в систему',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Кастомный AppBar
            Padding(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isFamilyListVisible = !isFamilyListVisible;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Мое здоровье',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayMedium
                                  ?.copyWith(
                                    fontFamily: 'Commissioner',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0B102B),
                                  ),
                            ),
                            SizedBox(width: appBarTitleSpacing),
                            if (familyMembers.length >
                                1) // Показываем иконку, только если есть члены семьи
                              SvgPicture.asset(
                                isFamilyListVisible
                                    ? 'assets/arrow_down.svg'
                                    : 'assets/arrow_down.svg',
                                width: 24,
                                height: 24,
                              ),
                          ],
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (String value) {
                              switch (value) {
                                case 'bracelet':
                                  break;
                                case 'privacy':
                                  _showPrivacySettings();
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'bracelet',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: Text(
                                    'Настройка браслета',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF0B102B),
                                        ),
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem<String>(
                                value: 'privacy',
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: Text(
                                    'Настройка приватности семьи',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: const Color(0xFF0B102B),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                            child: Transform.rotate(
                              angle: math.pi / 2,
                              child: SvgPicture.asset(
                                'assets/more.svg',
                                width: 32,
                                height: 32,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            color: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isFamilyListVisible && familyMembers.length > 1)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: familyMembers.map((member) {
                          return ListTile(
                            title: Text(
                              member.email,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF0B102B),
                                  ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedMember = member;
                                isFamilyListVisible = false;
                              });
                              // Обновляем виджеты с данными
                              _pulseKey.currentState?.refresh();
                              _bloodPressureKey.currentState?.refresh();
                              _stepsKey.currentState?.refresh();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton('Показатели', 0),
                          _buildTabButton('Документы', 1),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _selectedTab == 0
                        ? _buildIndicatorsContent()
                        : DocumentsScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedTab == index
                ? AppColors.primaryBlue
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _selectedTab == index
                  ? Colors.white
                  : const Color(0xFF0B102B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorsContent() {
    if (selectedMember == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            _buildHealthItem('Пульс',
                PulseWidget(key: _pulseKey, userId: selectedMember!.id)),
            _buildHealthItem(
                'Кровяное давление',
                BloodPressureWidget(
                    key: _bloodPressureKey, userId: selectedMember!.id)),
            _buildHealthItem('Шаги',
                StepsWidget(key: _stepsKey, userId: selectedMember!.id)),
            _buildBracerStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthItem(String title, Widget content) {
    return Container(
      margin: const EdgeInsets.all(4.0), // Отступы 4 со всех сторон
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Скругление 24
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // Сжимаем Column до минимального размера
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B102B),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFF818499), // Цвет rgba(129, 132, 153, 1)
                      ),
                      onPressed: () {
                        _showAddMeasurementBottomSheet(context, title);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => _getDetailScreen(title),
                          ),
                        );
                      },
                      child: SvgPicture.asset(
                        'assets/arrow_forward.svg',
                        width: 24,
                        height: 24,
                        color: const Color(0xFF0B102B), // Сохраняем тот же цвет
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          content, // Всегда добавляем content, скрытие пустого пространства обрабатывается внутри виджета
        ],
      ),
    );
  }

  void _showAddMeasurementBottomSheet(BuildContext context, String title) {
    if (selectedMember == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _getAddMeasurementWidget(title, selectedMember!.id),
        );
      },
    ).then((_) {
      _pulseKey.currentState?.refresh();
      _bloodPressureKey.currentState?.refresh();
      _stepsKey.currentState?.refresh();
    });
  }

  Widget _getAddMeasurementWidget(String title, String userId) {
    if (selectedMember == null) return Container();

    switch (title) {
      case 'Пульс':
        return AddPulse(title: title, userId: selectedMember!.id);
      case 'Кровяное давление':
        return AddBloodPressure(title: title, userId: selectedMember!.id);
      case 'Шаги':
        return AddSteps(title: title, userId: selectedMember!.id);
      default:
        return Container();
    }
  }

  Widget _getDetailScreen(String title) {
    if (selectedMember == null) return Container();

    switch (title) {
      case 'Пульс':
        return PulseDetailScreen(userId: selectedMember!.id);
      case 'Кровяное давление':
        return BloodPressureDetailScreen(userId: selectedMember!.id);
      case 'Шаги':
        return StepsDetailScreen(userId: selectedMember!.id);
      default:
        return Container();
    }
  }

  Widget _buildBracerStatus() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Image.asset(
            'assets/bracer_off.png',
            width: MediaQuery.of(context).size.width - 16,
            fit: BoxFit.fitWidth,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
