import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_aptechka/services/verification_screen.dart';
import 'package:my_aptechka/services/auth_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import '../styles.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
    _confirmPasswordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _register() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _emailError = email.isEmpty ? 'Введите почту' : null;
      _passwordError = password.isEmpty ? 'Введите пароль' : null;
      _confirmPasswordError = confirmPassword.isEmpty
          ? 'Повторите пароль'
          : password != confirmPassword
              ? 'Пароли не совпадают'
              : null;
    });

    if (email.isNotEmpty &&
        password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password == confirmPassword &&
        _isAgreed) {
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
                const SizedBox(height: 24),
                Text(
                  'Регистрация',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      cursorColor: AppColors.primaryBlue,
                      style: AppTextFieldStyles.textFieldTextStyle(context),
                      decoration: AppTextFieldStyles.defaultTextFieldDecoration(
                        context,
                        hintText: 'Email',
                        hasError: _emailError != null,
                        isFocused: _emailFocusNode.hasFocus,
                      ),
                    ),
                    if (_emailError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _emailError!,
                        style: AppTextFieldStyles.errorTextStyle(context),
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
                      style: AppTextFieldStyles.textFieldTextStyle(context),
                      decoration: AppTextFieldStyles.defaultTextFieldDecoration(
                        context,
                        hintText: 'Пароль',
                        hasError: _passwordError != null,
                        isFocused: _passwordFocusNode.hasFocus,
                      ),
                    ),
                    if (_passwordError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _passwordError!,
                        style: AppTextFieldStyles.errorTextStyle(context),
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
                      style: AppTextFieldStyles.textFieldTextStyle(context),
                      decoration: AppTextFieldStyles.defaultTextFieldDecoration(
                        context,
                        hintText: 'Повторите пароль',
                        hasError: _confirmPasswordError != null,
                        isFocused: _confirmPasswordFocusNode.hasFocus,
                      ),
                    ),
                    if (_confirmPasswordError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _confirmPasswordError!,
                        style: AppTextFieldStyles.errorTextStyle(context),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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