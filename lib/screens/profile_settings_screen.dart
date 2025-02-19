import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:provider/provider.dart';
import 'splash_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Настройки аккаунта',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsItem(context, 'Имя, фамилия', 'Не указано'),
                    _buildDivider(),
                    _buildPhoneSetting(context, userProvider),
                    _buildDivider(),
                    _buildSettingsItem(context, 'Почта', 'Не указана'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _logout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Выйти', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(CupertinoIcons.right_chevron,
                  size: 16, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneSetting(BuildContext context, UserProvider userProvider) {
    return FutureBuilder<String?>(
      future: userProvider.userId != null
          ? DatabaseService.getUserPhone(userProvider.userId!)
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return _buildSettingsItem(context, 'Телефон', 'Ошибка загрузки');
        }
        final phone = snapshot.data ?? 'Не указан';
        return _buildSettingsItem(context, 'Телефон', phone);
      },
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Colors.grey,
      height: 1,
      thickness: 0.5,
    );
  }

  void _logout(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await DatabaseService.logout(userProvider.userId!);
    userProvider.setUserId(null);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (Route<dynamic> route) => false,
    );
  }
}
