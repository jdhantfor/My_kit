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
                    _buildSettingsItem(
                        context,
                        'Имя, фамилия',
                        '${userProvider.name ?? ''} ${userProvider.surname ?? ''}'
                                .trim()
                                .isEmpty
                            ? 'Не указано'
                            : '${userProvider.name} ${userProvider.surname}'),
                    _buildDivider(),
                    _buildPhoneSetting(context, userProvider),
                    _buildDivider(),
                    _buildSettingsItem(
                        context, 'Почта', userProvider.email ?? 'Не указана'),
                    _buildDivider(),
                    _buildSettingsItem(
                        context,
                        'Пароль',
                        userProvider.password != null
                            ? '********'
                            : 'Не указан'),
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
    return GestureDetector(
      onTap: () {
        if (title == 'Имя, фамилия') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NameSurnameScreen()),
          );
        } else if (title == 'Телефон') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PhoneScreen()),
          );
        } else if (title == 'Почта') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EmailScreen()),
          );
        } else if (title == 'Пароль') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PasswordScreen()),
          );
        }
      },
      child: Padding(
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
      ),
    );
  }

  Widget _buildPhoneSetting(BuildContext context, UserProvider userProvider) {
    return FutureBuilder<String?>(
      future: DatabaseService.getUserPhone(userProvider.userId!),
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
      (Route route) => false,
    );
  }
}

class NameSurnameScreen extends StatefulWidget {
  const NameSurnameScreen({Key? key}) : super(key: key);

  @override
  _NameSurnameScreenState createState() => _NameSurnameScreenState();
}

class _NameSurnameScreenState extends State<NameSurnameScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();

  void _saveNameSurname() async {
    final name = _nameController.text;
    final surname = _surnameController.text;

    if (name.isNotEmpty && surname.isNotEmpty) {
      final userId = Provider.of<UserProvider>(context, listen: false).userId!;
      await DatabaseService.updateUserDetails(userId,
          name: name, surname: surname);

      // Обновляем данные в UserProvider
      Provider.of<UserProvider>(context, listen: false).setName(name);
      Provider.of<UserProvider>(context, listen: false).setSurname(surname);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Ваши имя, фамилия',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _surnameController,
              decoration: const InputDecoration(
                labelText: 'Фамилия',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveNameSurname,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size(MediaQuery.of(context).size.width - 40, 50),
              ),
              child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({Key? key}) : super(key: key);

  @override
  _PhoneScreenState createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();

  void _savePhoneNumber() async {
    final phone = _phoneController.text;

    if (phone.isNotEmpty) {
      final userId = Provider.of<UserProvider>(context, listen: false).userId!;
      await DatabaseService.updateUserDetails(userId, phone: phone);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Ваш телефон', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Телефон',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _savePhoneNumber,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size(MediaQuery.of(context).size.width - 40, 50),
              ),
              child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailScreen extends StatefulWidget {
  const EmailScreen({Key? key}) : super(key: key);

  @override
  _EmailScreenState createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController _emailController = TextEditingController();

  void _saveEmail() async {
    final email = _emailController.text;

    if (email.isNotEmpty) {
      final userId = Provider.of<UserProvider>(context, listen: false).userId!;
      await DatabaseService.updateUserDetails(userId, email: email);

      // Обновляем данные в UserProvider
      Provider.of<UserProvider>(context, listen: false).setEmail(email);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Ваша электронная почта',
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Электронная почта',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveEmail,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size(MediaQuery.of(context).size.width - 40, 50),
              ),
              child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({Key? key}) : super(key: key);

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();

  void _savePassword() async {
    final password = _passwordController.text;

    if (password.isNotEmpty) {
      final userId = Provider.of<UserProvider>(context, listen: false).userId!;
      await DatabaseService.updateUserDetails(userId, password: password);

      // Обновляем данные в UserProvider
      Provider.of<UserProvider>(context, listen: false).setPassword(password);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Ваш пароль', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _savePassword,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size(MediaQuery.of(context).size.width - 40, 50),
              ),
              child: const Text('Сохранить', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
