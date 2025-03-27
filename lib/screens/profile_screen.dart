import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:health/health.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/setting/stateful_widget.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'today/invite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_settings_screen.dart';
import 'braslet/health_sync_instruction_screen.dart';
import 'package:my_aptechka/styles.dart'; // Импортируем стили

// Модель для членов семьи
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  List<FamilyMember> familyMembers = []; // Список членов семьи

  @override
  void initState() {
    super.initState();
    _loadAvatar(); // Загружаем аватарку текущего пользователя
    _loadFamilyMembers(); // Загружаем членов семьи
  }

  Future<void> _loadAvatar() async {
    if (!mounted) return; // Проверяем, смонтирован ли виджет
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID пользователя не указан')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final uri = Uri.parse(
          'http://62.113.37.96:5001/download/$userId/profile/avatar.jpg');
      final response = await http.head(uri); // Проверяем, существует ли файл

      if (response.statusCode == 200) {
        userProvider.setAvatarUrl(uri.toString()); // Устанавливаем URL
      } else {
        userProvider.setAvatarUrl(null); // Сбрасываем, если файла нет
        print('Аватарка не найдена на сервере: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке аватарки: $e');
      userProvider.setAvatarUrl(null);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFamilyMembers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    final userEmail = userProvider.email;

    if (userId == null || userEmail == null) {
      print(
          'Ошибка: ID или email пользователя не указан. userId: $userId, userEmail: $userEmail');
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Добавляем локального пользователя в список
      final currentUser = FamilyMember(
        id: userId,
        name: userProvider.name ?? 'Имя не указано',
        email: userEmail,
        avatarUrl: userProvider.avatarUrl,
      );

      // Загружаем членов семьи с сервера
      final response = await http.get(
        Uri.parse('http://62.113.37.96:5002/family_members?user_id=$userId'),
      );

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

        if (!mounted) return;
        setState(() {
          familyMembers = [currentUser, ...members];
        });
      } else {
        print('Ошибка загрузки членов семьи: статус ${response.statusCode}');
        if (!mounted) return;
        setState(() {
          familyMembers = [currentUser];
        });
      }
    } catch (e) {
      print('Ошибка при загрузке членов семьи: $e');
      if (!mounted) return;
      setState(() {
        familyMembers = [
          FamilyMember(
            id: userId,
            name: userProvider.name ?? 'Имя не указано',
            email: userEmail,
            avatarUrl: userProvider.avatarUrl,
          )
        ];
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID пользователя не указан')),
        );
        return;
      }

      final uri = Uri.parse('http://62.113.37.96:5001/upload_avatar/$userId');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar',
          pickedFile.path,
          filename: 'avatar.jpg',
        ),
      );

      try {
        final response = await request.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final data = json.decode(responseData);
          final avatarUrl = data['avatar_url'];
          if (avatarUrl != null) {
            userProvider.setAvatarUrl(avatarUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Аватарка успешно загружена')),
            );
            _loadAvatar(); // Обновляем аватарку после загрузки
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Сервер не вернул URL аватарки')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка загрузки аватарки: ${response.statusCode}'),
            ),
          );
        }
      } catch (e) {
        print('Ошибка: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка соединения с сервером')),
        );
      }
    }
  }

  void _openFullScreenImage(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(
          imagePath: imagePath,
          onTap: () {
            if (imagePath == 'assets/sub1.png') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(
                    imagePath: 'assets/sub2.png',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  void _showInviteBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InviteScreen(),
                    ),
                  );
                },
                child: const Text('Пригласить через email'),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {},
                child: const Text('Пригласить другим способом'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _connectToHealth(BuildContext context) async {
    final health = Health();
    List<HealthDataType> types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE
    ];

    await Permission.activityRecognition.request();
    await Permission.sensors.request();

    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await health.getHealthConnectSdkStatus();
      print('Health Connect Status: ${status?.name}');
      if (status != HealthConnectSdkStatus.sdkAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Установите Health Connect для Android')),
        );
        return;
      }
    }

    bool authorized = await health.requestAuthorization(
      types,
      permissions: types.map((e) => HealthDataAccess.READ_WRITE).toList(),
    );
    if (!authorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Разрешения не получены')),
      );
      return;
    }

    await health.requestHealthDataHistoryAuthorization();

    DateTime now = DateTime.now();
    DateTime yesterday = now.subtract(const Duration(hours: 24));
    List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
      types: types,
      startTime: yesterday,
      endTime: now,
    );

    String userId = Provider.of<UserProvider>(context, listen: false).userId!;
    String steps = "0";
    String heartRate = "0";

    for (var data in healthData) {
      if (data.type == HealthDataType.STEPS) {
        steps = data.value.toString();
        await DatabaseService.saveSteps(userId, steps);
      } else if (data.type == HealthDataType.HEART_RATE) {
        heartRate = data.value.toString();
        await DatabaseService.saveHeartRate(userId, heartRate);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Данные получены: шаги $steps, пульс $heartRate')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: AppColors.secondaryGrey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Consumer<UserProvider>(
                              builder: (context, userProvider, child) {
                                return GestureDetector(
                                  onTap: () async {
                                    await _uploadAvatar(context);
                                  },
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: const Color.fromARGB(
                                        255, 231, 231, 231),
                                    child: userProvider.avatarUrl != null
                                        ? ClipOval(
                                            child: Image.network(
                                              userProvider.avatarUrl!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                if (progress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  size: 48,
                                                  color:
                                                      AppColors.secondaryGrey,
                                                );
                                              },
                                            ),
                                          )
                                        : SvgPicture.asset(
                                            'assets/add.svg',
                                            width: 40,
                                            height: 40,
                                            color: AppColors.secondaryGrey,
                                          ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: () => _showInviteBottomSheet(context),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.activeFieldBlue,
                                child: SvgPicture.asset(
                                  'assets/add.svg',
                                  width: 30,
                                  height: 30,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          userProvider.name ?? 'Имя не указано',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProfileSettingsScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Настройки аккаунта',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(color: AppColors.primaryBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 8.0),
                    child: GestureDetector(
                      onTap: () =>
                          _openFullScreenImage(context, 'assets/sub1.png'),
                      child: Image.asset(
                        'assets/subscrube.png',
                        width: MediaQuery.of(context).size.width - 48,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      top: 4,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSquareBox(
                            context: context,
                            icon: 'assets/bracer.svg',
                            title: 'Умный браслет',
                            subtitle: 'не добавлен',
                            rightIcon: 'assets/add.svg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HealthSyncInstructionScreen(
                                    onContinue: () => _connectToHealth(context),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSquareBox(
                            context: context,
                            icon: 'assets/notif.svg',
                            title: 'Уведомления',
                            subtitle: 'все',
                            rightIcon: 'assets/arrow_forward.svg',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4, right: 4),
                    child: _buildWideBox(context),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSquareBox({
    required BuildContext context,
    required String icon,
    required String title,
    required String subtitle,
    String? rightIcon,
    String? leftIcon,
    VoidCallback? onTap,
  }) {
    final userProvider = Provider.of<UserProvider>(context);

    return GestureDetector(
      onTap: onTap ??
          () {
            if (title == 'Уведомления') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsSettingsScreen(
                    userId: userProvider.userId!,
                  ),
                ),
              );
            }
          },
      child: Container(
        height: 120,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset(
                        icon,
                        width: 24,
                        height: 24,
                      ),
                      if (rightIcon != null)
                        SvgPicture.asset(
                          rightIcon,
                          width: 24,
                          height: 24,
                          color: AppColors.secondaryGrey,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: AppColors.secondaryGrey),
                  ),
                ],
              ),
            ),
            if (leftIcon != null)
              Positioned(
                left: 16,
                bottom: 16,
                child: SvgPicture.asset(
                  leftIcon,
                  width: 24,
                  height: 24,
                  color: AppColors.secondaryGrey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideBox(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              'assets/famaly.svg',
              width: 24,
              height: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'Настройки семьи',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            // Список членов семьи
            ...familyMembers.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              return Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            const Color.fromARGB(255, 197, 197, 197),
                        child: ClipOval(
                          child: member.avatarUrl != null
                              ? Image.network(
                                  member.avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 40,
                                  height: 40,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) {
                                      return child;
                                    }
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 24,
                                      color: AppColors.secondaryGrey,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.person,
                                  size: 24,
                                  color: AppColors.secondaryGrey,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            member.email,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: AppColors.secondaryGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 8),
                ],
              );
            }),
            // Кнопка "Пригласить участника"
            GestureDetector(
              onTap: () => _showInviteBottomSheet(context),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.activeFieldBlue,
                    child: SvgPicture.asset(
                      'assets/add.svg',
                      width: 24,
                      height: 24,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Пригласить участника',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTap;

  const FullScreenImage({super.key, required this.imagePath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: onTap,
        child: SingleChildScrollView(
          child: Image.asset(
            imagePath,
            fit: BoxFit.fitWidth,
            width: MediaQuery.of(context).size.width,
          ),
        ),
      ),
    );
  }
}
