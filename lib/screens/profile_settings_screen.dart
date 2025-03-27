import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Настройки аккаунта',
          style: TextStyle(
            fontFamily: 'Commissioner',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0B102B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
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
                                : '${userProvider.name ?? ''} ${userProvider.surname ?? ''}',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const NameSurnameScreen()),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildPhoneSetting(context, userProvider),
                          _buildDivider(),
                          _buildSettingsItem(
                            context,
                            'Электронная почта',
                            userProvider.email ?? 'Не указана',
                            isClickable: false, // Делаем некликабельным
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            context,
                            'Пароль',
                            userProvider.password != null
                                ? '********'
                                : '*******',
                            onTap: () => _sendPasswordResetEmail(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _logout(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE2E2),
                            foregroundColor: const Color(0xFFEF4444),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Выйти',
                            style: TextStyle(
                              fontFamily: 'Commissioner',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Center(
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/logos.svg',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'версия 1.0',
                    style: TextStyle(
                      fontFamily: 'Commissioner',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, String title, String value,
      {VoidCallback? onTap, bool isClickable = true}) {
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Commissioner',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Commissioner',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF0B102B),
                  ),
                ),
                if (isClickable)
                  SvgPicture.asset(
                    'assets/arrow_forward.svg',
                    width: 16,
                    height: 16,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSetting(BuildContext context, UserProvider userProvider) {
    return _buildSettingsItem(
      context,
      'Телефон',
      userProvider.phone ?? 'Не указан',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PhoneScreen()),
        );
      },
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Color(0xFFE5E7EB),
      height: 1,
      thickness: 0.5,
    );
  }

  void _logout(BuildContext context) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (userProvider.userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: ID пользователя отсутствует')),
        );
        return;
      }

      await DatabaseService.logout(userProvider.userId!);
      await FirebaseAuth.instance.signOut(); // Выход из Firebase
      userProvider.setUserId(null);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вы успешно вышли из аккаунта')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при выходе: $e')),
      );
    }
  }

  void _sendPasswordResetEmail(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Ошибка: Пользователь не авторизован или email отсутствует')),
        );
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Письмо для сброса пароля отправлено на ваш email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отправке письма: $e')),
      );
    }
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
  int _nameCharCount = 0;
  int _surnameCharCount = 0;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.name != null) _nameController.text = userProvider.name!;
    if (userProvider.surname != null)
      _surnameController.text = userProvider.surname!;
    _nameController.addListener(_updateNameCharCount);
    _surnameController.addListener(_updateSurnameCharCount);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateNameCharCount);
    _surnameController.removeListener(_updateSurnameCharCount);
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  void _updateNameCharCount() {
    setState(() {
      _nameCharCount = _nameController.text.length;
    });
  }

  void _updateSurnameCharCount() {
    setState(() {
      _surnameCharCount = _surnameController.text.length;
    });
  }

  void _saveNameSurname() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();

    if (name.isEmpty && surname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите хотя бы имя или фамилию')),
      );
      return;
    }

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: ID пользователя отсутствует')),
        );
        return;
      }

      await DatabaseService.updateUserDetails(
        userId,
        name: name.isNotEmpty ? name : null,
        surname: surname.isNotEmpty ? surname : null,
      );

      if (name.isNotEmpty) {
        Provider.of<UserProvider>(context, listen: false).setName(name);
      }
      if (surname.isNotEmpty) {
        Provider.of<UserProvider>(context, listen: false).setSurname(surname);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные успешно сохранены')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Имя, фамилия',
          style: TextStyle(
            fontFamily: 'Commissioner',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0B102B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.activeFieldBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Имя',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                      Text(
                        '$_nameCharCount/25',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '',
                      contentPadding: EdgeInsets.only(bottom: 8),
                      filled: false,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF0B102B),
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                    maxLength: 25,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.activeFieldBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Фамилия',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                      Text(
                        '$_surnameCharCount/25',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _surnameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '',
                      contentPadding: EdgeInsets.only(bottom: 8),
                      filled: false,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF0B102B),
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                    maxLength: 25,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveNameSurname,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(MediaQuery.of(context).size.width - 32, 50),
              ),
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
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
  int _phoneCharCount = 0;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.phone != null) _phoneController.text = userProvider.phone!;
    _phoneController.addListener(_updatePhoneCharCount);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_updatePhoneCharCount);
    _phoneController.dispose();
    super.dispose();
  }

  void _updatePhoneCharCount() {
    setState(() {
      _phoneCharCount = _phoneController.text.length;
    });
  }

  void _savePhoneNumber() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер телефона')),
      );
      return;
    }

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: ID пользователя отсутствует')),
        );
        return;
      }

      await DatabaseService.updateUserDetails(userId, phone: phone);
      Provider.of<UserProvider>(context, listen: false).setPhone(phone);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Номер телефона успешно сохранён')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Телефон',
          style: TextStyle(
            fontFamily: 'Commissioner',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0B102B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.activeFieldBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Телефон',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                      Text(
                        '$_phoneCharCount/15',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '',
                      contentPadding: EdgeInsets.only(bottom: 8),
                      filled: false,
                    ),
                    keyboardType: TextInputType.phone,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF0B102B),
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                    maxLength: 15,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _savePhoneNumber,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(MediaQuery.of(context).size.width - 32, 50),
              ),
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
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
  int _emailCharCount = 0;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.email != null) _emailController.text = userProvider.email!;
    _emailController.addListener(_updateEmailCharCount);
  }

  @override
  void dispose() {
    _emailController.removeListener(_updateEmailCharCount);
    _emailController.dispose();
    super.dispose();
  }

  void _updateEmailCharCount() {
    setState(() {
      _emailCharCount = _emailController.text.length;
    });
  }

  void _saveEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите электронную почту')),
      );
      return;
    }

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: ID пользователя отсутствует')),
        );
        return;
      }

      await DatabaseService.updateUserDetails(userId, email: email);
      Provider.of<UserProvider>(context, listen: false).setEmail(email);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Электронная почта успешно сохранена')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Электронная почта',
          style: TextStyle(
            fontFamily: 'Commissioner',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0B102B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.activeFieldBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Электронная почта',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                      Text(
                        '$_emailCharCount/50',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '',
                      contentPadding: EdgeInsets.only(bottom: 8),
                      filled: false,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF0B102B),
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                    maxLength: 50,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(MediaQuery.of(context).size.width - 32, 50),
              ),
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
