import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_aptechka/services/verification_screen.dart';
import 'package:my_aptechka/services/auth_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import '../styles.dart'; // Импортируем стили

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String? _emailError;
  String? _passwordError;
  bool _isAgreed = false;

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

  void _register() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _emailError = email.isEmpty ? 'Введите почту' : null;
      _passwordError = password.isEmpty ? 'Введите пароль' : null;
    });

    if (email.isNotEmpty && password.isNotEmpty && _isAgreed) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      try {
        await authService.register(email, password, userProvider);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const VerificationScreen()),
        );
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'weak-password':
            setState(() {
              _passwordError = 'Пароль слишком слабый';
            });
            break;
          case 'email-already-in-use':
            setState(() {
              _emailError = 'Этот email уже используется';
            });
            break;
          case 'invalid-email':
            setState(() {
              _emailError = 'Неверный формат email';
            });
            break;
          default:
            setState(() {
              _emailError = 'Ошибка регистрации: ${e.message}';
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
                  'Регистрация',
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
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Центрируем по вертикали
                  children: [
                    Checkbox(
                      value: _isAgreed,
                      onChanged: (value) {
                        setState(() {
                          _isAgreed = value ?? false;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Я принимаю ',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.secondaryGrey,
                                  ),
                            ),
                            TextSpan(
                              text:
                                  'Политику\u00A0конфиденциальности\u00A0и\u00A0пользовательское\u00A0соглашение',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.primaryBlue,
                                  ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  _launchUrl(
                                      'https://my-kit.ru/user-agreement');
                                },
                            ),
                            TextSpan(
                              text: '.',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.secondaryGrey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAgreed ? _register : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAgreed
                          ? AppColors.primaryBlue
                          : Colors.grey.shade400,
                    ),
                    child: const Text('Зарегистрироваться'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
