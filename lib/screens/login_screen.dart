import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'registration_screen.dart';
import 'package:my_aptechka/services/auth_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import '../styles.dart'; // Импортируем стили

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    // Добавляем слушатели для FocusNode
    _emailFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _emailError = email.isEmpty ? 'Введите почту' : null;
      _passwordError = password.isEmpty ? 'Введите пароль' : null;
    });

    if (email.isNotEmpty && password.isNotEmpty) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      try {
        await authService.login(email, password, userProvider);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'user-not-found':
            setState(() {
              _emailError = 'Пользователь не найден';
            });
            break;
          case 'wrong-password':
            setState(() {
              _passwordError = 'Неверный пароль';
            });
            break;
          case 'invalid-email':
            setState(() {
              _emailError = 'Неверный формат email';
            });
            break;
          default:
            setState(() {
              _emailError = 'Ошибка входа: ${e.message}';
            });
        }
      }
    }
  }

  // Метод для открытия ссылки
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
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
                  'Ваша почта и пароль',
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
                      style:
                          Theme.of(context).textTheme.bodyMedium, // body 16/med
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
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: true,
                      cursorColor: AppColors.primaryBlue,
                      style:
                          Theme.of(context).textTheme.bodyMedium, // body 16/med
                      decoration: InputDecoration(
                        hintText: 'Пароль',
                        filled: true,
                        fillColor: _passwordError != null
                            ? AppColors.errorFieldRed
                            : _passwordFocusNode.hasFocus
                                ? AppColors.activeFieldBlue
                                : AppColors.fieldBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _passwordError!,
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
                    onPressed: _login,
                    child: const Text('Войти'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const RegistrationScreen()),
                      );
                    },
                    child: const Text('Зарегистрироваться'),
                  ),
                ),
              ],
            ),
            // Текст внизу экрана
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Продолжая авторизацию, вы принимаете ',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.secondaryGrey,
                          ),
                    ),
                    TextSpan(
                      text: 'условия\u00A0пользовательского\u00A0соглашения',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _launchUrl('https://my-kit.ru/user-agreement');
                        },
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
