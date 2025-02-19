import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Добавляем пакет для выбора изображений
import 'today/invite.dart';
import 'package:my_aptechka/screens/profile_settings_screen.dart';
import 'setting/smart_bandsettings_screen.dart';
import 'setting/stateful_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Здесь можно сохранить путь к изображению или отобразить его напрямую
      print('Выбрано изображение: ${pickedFile.path}');
      // Вы можете передать этот путь в UI, чтобы отобразить выбранное изображение
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
                  Navigator.pop(context); // Закрываем нижний лист
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InviteScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  minimumSize: Size(MediaQuery.of(context).size.width - 40, 50),
                ),
                child: const Text(
                  'Пригласить через номер телефона',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  // Действие для "Пригласить другим способом"
                },
                child: const Text(
                  'Пригласить другим способом',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
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
                      // Прозрачный кружок слева
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Color.fromARGB(127, 252, 252, 252),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Центральный кружок
                      GestureDetector(
                        onTap: () async {
                          await _pickImage(
                              context); // Вызов метода для выбора изображения
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              const Color.fromARGB(255, 231, 231, 231),
                          backgroundImage: null, // Убираем сетевое изображение
                          child: const Icon(
                            Icons
                                .add_a_photo, // Временный иконка для добавления фото
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Правый кружок с голубым прозрачным фоном и голубым плюсиком
                      GestureDetector(
                        onTap: () => _showInviteBottomSheet(
                            context), // Логика для плюсика
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor:
                              const Color.fromRGBO(25, 127, 242, 0.2),
                          child: const Icon(
                            Icons.add,
                            size: 30,
                            color: Color.fromRGBO(25, 127, 242, 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Константин',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Настройки аккаунта',
                      style: TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: GestureDetector(
                onTap: () => _openFullScreenImage(context, 'assets/sub1.png'),
                child: Image.asset(
                  'assets/subscrube.png',
                  width: MediaQuery.of(context).size.width - 4,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSquareBox(
                      context: context, // Pass the context here
                      icon: 'assets/braslet.png',
                      title: 'Умный браслет',
                      subtitle: 'не добавлен',
                      rightIcon: Icons.add,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: _buildSquareBox(
                      context: context, // Pass the context here
                      icon: 'assets/noti.png',
                      title: 'Уведомления',
                      subtitle: 'все',
                      rightIcon: Icons.arrow_forward_ios,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
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
    IconData? rightIcon,
    IconData? leftIcon,
  }) {
    return GestureDetector(
      onTap: () {
        if (title == 'Умный браслет') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SmartBandSettingsScreen(),
            ),
          );
        } else if (title == 'Уведомления') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NotificationsSettingsScreen(),
            ),
          );
        }
      },
      child: Container(
        height: 120,
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
                      Image.asset(icon, width: 24, height: 24),
                      if (rightIcon != null)
                        Icon(rightIcon, color: Colors.grey, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            if (leftIcon != null)
              Positioned(
                left: 16,
                bottom: 16,
                child: Icon(leftIcon, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideBox(BuildContext context) {
    return Container(
      width: double.infinity,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/famaly.png', width: 24, height: 24),
            const SizedBox(height: 8),
            const Text('Настройки семьи',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color.fromARGB(255, 197, 197, 197),
                  child: Icon(
                    Icons.person,
                    size: 24,
                    color: Color.fromARGB(255, 148, 147, 147),
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ВЫ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('+7(999) 999-99-99',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            Divider(color: Colors.grey[300]),
            GestureDetector(
              onTap: () => _showInviteBottomSheet(context),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue[50],
                    child: const Icon(Icons.add, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  const Text('Пригласить участника',
                      style: TextStyle(color: Colors.blue)),
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
