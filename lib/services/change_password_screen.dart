import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:provider/provider.dart';
import 'package:my_aptechka/services/auth_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import '../styles.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _currentPasswordFocusNode.addListener(() {
      setState(() {});
    });
    _newPasswordFocusNode.addListener(() {
      setState(() {});
    });
    _confirmPasswordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _changePassword() async {
    final String currentPassword = _currentPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _currentPasswordError = currentPassword.isEmpty ? 'Введите текущий пароль' : null;
      _newPasswordError = newPassword.isEmpty ? 'Введите новый пароль' : null;
      _confirmPasswordError = confirmPassword.isEmpty ? 'Подтвердите новый пароль' : null;
    });

    if (currentPassword.isNotEmpty && newPassword.isNotEmpty && confirmPassword.isNotEmpty) {
      if (newPassword != confirmPassword) {
        setState(() {
          _confirmPasswordError = 'Пароли не совпадают';
        });
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь не авторизован')),
        );
        return;
      }

      try {
        // Проверяем текущий пароль
        final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);

        // Обновляем пароль
        await user.updatePassword(newPassword);

        // Обновляем пароль в локальной базе данных
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await DatabaseService.updateUserDetails(userProvider.userId!, password: newPassword);

        // Синхронизируем с сервером
        await DatabaseService().syncWithServer(userProvider.userId!);

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пароль успешно изменён')),
        );
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'wrong-password':
            setState(() {
              _currentPasswordError = 'Неверный текущий пароль';
            });
            break;
          case 'weak-password':
            setState(() {
              _newPasswordError = 'Пароль слишком слабый';
            });
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ошибка: ${e.message}')),
            );
        }
      }
    }
  }

  void _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован или email не указан')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Письмо для сброса пароля отправлено на ваш email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при отправке письма: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Изменение пароля',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _currentPasswordController,
                      focusNode: _currentPasswordFocusNode,
                      obscureText: true,
                      cursorColor: AppColors.primaryBlue,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Текущий пароль',
                        filled: true,
                        fillColor: _currentPasswordError != null
                            ? AppColors.errorFieldRed
                            : _currentPasswordFocusNode.hasFocus
                                ? AppColors.activeFieldBlue
                                : AppColors.fieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_currentPasswordError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _currentPasswordError!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFE54045),
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _newPasswordController,
                      focusNode: _newPasswordFocusNode,
                      obscureText: true,
                      cursorColor: AppColors.primaryBlue,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Новый пароль',
                        filled: true,
                        fillColor: _newPasswordError != null
                            ? AppColors.errorFieldRed
                            : _newPasswordFocusNode.hasFocus
                                ? AppColors.activeFieldBlue
                                : AppColors.fieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_newPasswordError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _newPasswordError!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFE54045),
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocusNode,
                      obscureText: true,
                      cursorColor: AppColors.primaryBlue,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Подтвердите новый пароль',
                        filled: true,
                        fillColor: _confirmPasswordError != null
                            ? AppColors.errorFieldRed
                            : _confirmPasswordFocusNode.hasFocus
                                ? AppColors.activeFieldBlue
                                : AppColors.fieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_confirmPasswordError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _confirmPasswordError!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFE54045),
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _changePassword,
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Забыли пароль?',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                      recognizer: TapGestureRecognizer()..onTap = _resetPassword,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}