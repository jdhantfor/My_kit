import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:my_aptechka/services/change_password_screen.dart';
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
                            isClickable: false,
                          ),
                          _buildDivider(),
                          _buildSettingsItem(
                            context,
                            'Пароль',
                            userProvider.password != null ? '********' : '*******',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                              );
                            },
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
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showDeleteAccountDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5E7EB),
                            foregroundColor: const Color(0xFF6B7280),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Удалить аккаунт',
                            style: TextStyle(
                              fontFamily: 'Commissioner',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
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
                  Image.asset(
                    'assets/icon.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'версия 1.5.4',
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
      print('Logout: Начало процесса выхода...');
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (userProvider.userId == null) {
        print('Logout: Ошибка: ID пользователя отсутствует');
        return;
      }

      print('Logout: Вызов DatabaseService.logout для userId: ${userProvider.userId}');
      await DatabaseService.logout(userProvider.userId!);
      print('Logout: DatabaseService.logout успешно выполнен');

      print('Logout: Выход из FirebaseAuth...');
      await FirebaseAuth.instance.signOut();
      print('Logout: Выход из FirebaseAuth успешен');

      print('Logout: Очистка UserProvider...');
      userProvider.setUserId(null);
      print('Logout: UserProvider очищен');

      print('Logout: Перенаправление на экран логина...');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
      print('Logout: Навигация выполнена');
    } catch (e) {
      print('Logout: Ошибка при выходе: $e');
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    print('DeleteAccountDialog: Открытие диалога подтверждения удаления...');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Удалить аккаунт',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B102B),
            ),
          ),
          content: const Text(
            'Вы уверены, что хотите удалить аккаунт? Это действие нельзя отменить.',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('DeleteAccountDialog: Нажата кнопка "Отмена"');
                Navigator.of(context).pop();
              },
              child: const Text(
                'Отмена',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                print('DeleteAccountDialog: Нажата кнопка "Удалить"');
                Navigator.of(context).pop();
                _showPasswordDialog(context);
              },
              child: const Text(
                'Удалить',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        );
      },
    );
  }

  void _showPasswordDialog(BuildContext context) {
    print('PasswordDialog: Открытие диалога ввода пароля...');
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Подтверждение',
            style: TextStyle(
              fontFamily: 'Commissioner',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B102B),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Введите ваш пароль для подтверждения удаления аккаунта.',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Пароль',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('PasswordDialog: Нажата кнопка "Отмена"');
                Navigator.of(context).pop();
              },
              child: const Text(
                'Отмена',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                print('PasswordDialog: Нажата кнопка "Подтвердить" с паролем: ${passwordController.text}');
                Navigator.of(context).pop();
                _deleteAccount(context, passwordController.text);
              },
              child: const Text(
                'Подтвердить',
                style: TextStyle(
                  fontFamily: 'Commissioner',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        );
      },
    );
  }

  void _deleteAccount(BuildContext context, String password) async {
    try {
      print('DeleteAccount: Шаг 1: Начало процесса удаления аккаунта...');
      
      // Получаем данные пользователя
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || userProvider.userId == null) {
        print('DeleteAccount: Шаг 2: Ошибка: Пользователь или userId отсутствует');
        return;
      }

      print('DeleteAccount: Шаг 3: Пользователь найден, userId: ${userProvider.userId}, email: ${user.email}');

      // Повторная аутентификация
      print('DeleteAccount: Шаг 4: Повторная аутентификация с паролем: $password');
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      try {
        await user.reauthenticateWithCredential(credential);
        print('DeleteAccount: Шаг 5: Повторная аутентификация успешна');
      } catch (reauthError) {
        print('DeleteAccount: Шаг 5: Ошибка повторной аутентификации: $reauthError');
        throw reauthError;
      }

      // Удаляем данные из базы через DatabaseService.deleteUser
      print('DeleteAccount: Шаг 6: Вызов DatabaseService.deleteUser для userId: ${userProvider.userId}');
      try {
        await DatabaseService.deleteUser(userProvider.userId!);
        print('DeleteAccount: Шаг 7: Данные успешно удалены из базы через DatabaseService');
      } catch (dbError) {
        print('DeleteAccount: Шаг 7: Ошибка удаления данных из базы: $dbError');
        // Продолжаем процесс, даже если база не удалилась, чтобы удалить аккаунт из Firebase
      }

      // Удаляем аккаунт из Firebase
      print('DeleteAccount: Шаг 8: Удаление аккаунта из Firebase...');
      try {
        await user.delete();
        print('DeleteAccount: Шаг 9: Аккаунт успешно удалён из Firebase');
      } catch (firebaseError) {
        print('DeleteAccount: Шаг 9: Ошибка удаления из Firebase: $firebaseError');
        throw firebaseError;
      }

      // Очищаем UserProvider
      print('DeleteAccount: Шаг 10: Очистка UserProvider...');
      userProvider.setUserId(null);
      print('DeleteAccount: Шаг 11: UserProvider успешно очищен');

      // Выполняем логаут из Firebase
      print('DeleteAccount: Шаг 12: Логаут из FirebaseAuth...');
      try {
        await FirebaseAuth.instance.signOut();
        print('DeleteAccount: Шаг 13: Логаут из FirebaseAuth успешен');
      } catch (logoutError) {
        print('DeleteAccount: Шаг 13: Ошибка логаута из FirebaseAuth: $logoutError');
        // Продолжаем, так как аккаунт уже удалён
      }

      // Перенаправляем на экран логина
      print('DeleteAccount: Шаг 14: Перенаправление на экран логина...');
      try {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
        print('DeleteAccount: Шаг 15: Навигация успешно выполнена');
      } catch (navError) {
        print('DeleteAccount: Шаг 15: Ошибка навигации: $navError');
      }
    } catch (e) {
      print('DeleteAccount: Шаг 16: Ошибка при удалении аккаунта: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') {
          print('DeleteAccount: Неверный пароль. Пожалуйста, попробуйте снова.');
        } else if (e.code == 'requires-recent-login') {
          print('DeleteAccount: Для удаления аккаунта требуется повторный вход. Пожалуйста, выйдите и войдите снова.');
        }
      }
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

      await DatabaseService().syncWithServer(userId);

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

      await DatabaseService().syncWithServer(userId);

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