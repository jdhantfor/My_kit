import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/setting/stateful_widget.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:my_aptechka/services/subscription_intro_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'today/invite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'profile_settings_screen.dart';
import 'braslet/health_sync_instruction_screen.dart';
import 'setting/family_member_privacy_settings_screen.dart';
import 'package:my_aptechka/styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

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
  List<FamilyMember> familyMembers = [];
  bool _showBanner = true;
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    print('ProfileScreen: initState started');
    _pageController = PageController(viewportFraction: 0.3);
    _loadAvatar();
    _loadFamilyMembers();
    _loadSubscriptionStatus();
    _loadBannerState();
    print('ProfileScreen: initState finished');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showBanner = prefs.getBool('showBanner') ?? true;
    });
  }

  Future<void> _hideBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showBanner', false);
    setState(() {
      _showBanner = false;
    });
  }

  Future<void> _loadSubscriptionStatus() async {
    print('ProfileScreen: _loadSubscriptionStatus started');
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    print('ProfileScreen: userId from UserProvider: $userId');
    if (userId != null) {
      final userData = await DatabaseService.getUserDetails(userId);
      print('ProfileScreen: userData from DatabaseService: $userData');
      if (userData != null) {
        userProvider.setSubscribe(userData['subscribe'] == 1);
        print('ProfileScreen: Subscription status set to: ${userData['subscribe'] == 1}');
      } else {
        print('ProfileScreen: userData is null, subscription not set');
      }
    } else {
      print('ProfileScreen: userId is null, cannot load subscription status');
    }
    print('ProfileScreen: _loadSubscriptionStatus finished');
  }

  Future<void> _loadAvatar() async {
    if (!mounted) return;
    print('ProfileScreen: _loadAvatar started');
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.userId;
    print('ProfileScreen: userId for avatar: $userId');

    if (userId == null) {
      if (!mounted) return;
      print('ProfileScreen: userId is null, cannot load avatar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID пользователя не указан')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      final uri = Uri.parse(
          'http://62.113.37.96:5001/download/$userId/profile/avatar.jpg');
      print('ProfileScreen: Avatar request URL: $uri');
      final response = await http.head(uri);
      print('ProfileScreen: Avatar response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        userProvider.setAvatarUrl(uri.toString());
      } else {
        userProvider.setAvatarUrl(null);
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
      final currentUser = FamilyMember(
        id: userId,
        name: userProvider.name ?? 'Имя не указано',
        email: userEmail,
        avatarUrl: userProvider.avatarUrl,
      );

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
      print('ProfileScreen: _loadFamilyMembers finished');
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
            _loadAvatar();
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

  void _showInviteBottomSheet(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.subscribe) {
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
    } else {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionIntroScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    print('ProfileScreen: build started');
    print('ProfileScreen: userProvider.name: ${userProvider.name}');
    print('ProfileScreen: userProvider.email: ${userProvider.email}');
    print('ProfileScreen: userProvider.subscribe: ${userProvider.subscribe}');
    print('ProfileScreen: familyMembers: $familyMembers');
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
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 120,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: familyMembers.length + 1,
                            onPageChanged: (int page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                            itemBuilder: (context, index) {
                              if (index == familyMembers.length) {
                                return Transform.scale(
                                  scale: _currentPage == index ? 1.0 : 0.7,
                                  child: Opacity(
                                    opacity: _currentPage == index ? 1.0 : 0.5,
                                    child: GestureDetector(
                                      onTap: () => _showInviteBottomSheet(context),
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: userProvider.subscribe
                                            ? AppColors.activeFieldBlue
                                            : AppColors.secondaryGrey.withOpacity(0.2),
                                        child: SvgPicture.asset(
                                          'assets/add.svg',
                                          width: 40,
                                          height: 40,
                                          color: userProvider.subscribe
                                              ? AppColors.primaryBlue
                                              : AppColors.secondaryGrey,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final member = familyMembers[index];
                              return Transform.scale(
                                scale: _currentPage == index ? 1.0 : 0.7,
                                child: Opacity(
                                  opacity: _currentPage == index ? 1.0 : 0.5,
                                  child: GestureDetector(
                                    onTap: () {
                                      _pageController.animateToPage(
                                        index,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: const Color.fromARGB(255, 231, 231, 231),
                                      child: member.avatarUrl != null
                                          ? ClipOval(
                                              child: Image.network(
                                                member.avatarUrl!,
                                                fit: BoxFit.cover,
                                                width: 100,
                                                height: 100,
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
                                                    size: 48,
                                                    color: AppColors.secondaryGrey,
                                                  );
                                                },
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 48,
                                              color: AppColors.secondaryGrey,
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _currentPage < familyMembers.length
                              ? familyMembers[_currentPage].name
                              : 'Пригласить',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 8),
                        if (_currentPage < familyMembers.length)
                          GestureDetector(
                            onTap: () {
                              if (_currentPage == 0) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileSettingsScreen(),
                                  ),
                                );
                              } else {
                                final member = familyMembers[_currentPage];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FamilyMemberPrivacySettingsScreen(
                                      memberId: member.id,
                                      memberEmail: member.email,
                                    ),
                                  ),
                                ).then((value) {
                                  if (value == true) {
                                    _loadFamilyMembers();
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _currentPage == 0
                                    ? 'Настройки аккаунта'
                                    : 'Настройки приватности',
                                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (Platform.isAndroid && _showBanner)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SubscriptionIntroScreen()),
                          );
                        },
                        child: _buildSubscriptionBanner(context),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 4),
                    child: Row(
                      children: [
                        if (Platform.isAndroid)
                          Expanded(
                            child: _buildSquareBox(
                              context: context,
                              icon: 'assets/bracer.svg',
                              title: 'Умный браслет',
                              subtitle: 'не добавлен',
                              rightIcon: 'assets/add.svg',
                              onTap: () {},
                            ),
                          ),
                        if (Platform.isAndroid) const SizedBox(width: 4),
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

  Widget _buildSubscriptionBanner(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width - 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: AssetImage('assets/banner_bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'С подпиской больше возможностей',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Подключение браслетов, контроль\nздоровья родственников и не только',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Подключить',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: _hideBanner,
            child: const Icon(
              Icons.close,
              color: Colors.grey,
              size: 24,
            ),
          ),
        ),
      ],
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.userId;

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
            ...familyMembers.asMap().entries.map((entry) {
              final index = entry.key;
              final member = entry.value;
              return Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color.fromARGB(255, 197, 197, 197),
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
                      const Spacer(),
                      if (member.id != currentUserId)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FamilyMemberPrivacySettingsScreen(
                                  memberId: member.id,
                                  memberEmail: member.email,
                                ),
                              ),
                            ).then((value) {
                              if (value == true) {
                                _loadFamilyMembers();
                              }
                            });
                          },
                          child: SvgPicture.asset(
                            'assets/arrow_forward.svg',
                            width: 24,
                            height: 24,
                            color: AppColors.secondaryGrey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 8),
                ],
              );
            }),
            GestureDetector(
              onTap: () => _showInviteBottomSheet(context),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: userProvider.subscribe
                        ? AppColors.activeFieldBlue
                        : AppColors.secondaryGrey.withOpacity(0.2),
                    child: SvgPicture.asset(
                      'assets/add.svg',
                      width: 24,
                      height: 24,
                      color: userProvider.subscribe
                          ? AppColors.primaryBlue
                          : AppColors.secondaryGrey,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Пригласить участника',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: userProvider.subscribe
                              ? AppColors.primaryBlue
                              : AppColors.secondaryGrey,
                        ),
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