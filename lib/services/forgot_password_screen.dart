import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:my_aptechka/services/auth_service.dart';
import '../styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    final String email = _emailController.text.trim();

    setState(() {
      _emailError = email.isEmpty ? 'Введите почту' : null;
    });

    if (email.isNotEmpty) {
      final authService = Provider.of<AuthService>(context, listen: false);

      try {
        await authService.sendPasswordResetEmail(email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Письмо для сброса пароля отправлено на ваш email'),
          ),
        );
        Navigator.of(context).pop(); // Возвращаемся на экран входа
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'invalid-email':
            setState(() {
              _emailError = 'Неверный формат email';
            });
            break;
          case 'user-not-found':
            setState(() {
              _emailError = 'Пользователь с таким email не найден';
            });
            break;
          default:
            setState(() {
              _emailError = 'Ошибка: ${e.message}';
            });
        }
      } catch (e) {
        setState(() {
          _emailError = 'Ошибка: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Восстановление пароля',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Введите ваш email',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: AppColors.primaryBlue,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: _emailError != null
                        ? AppColors.errorFieldRed
                        : _emailFocusNode.hasFocus
                            ? AppColors.activeFieldBlue
                            : AppColors.fieldBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (_emailError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _emailError!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFE54045),
                        ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetPassword,
                child: const Text('Отправить письмо'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}