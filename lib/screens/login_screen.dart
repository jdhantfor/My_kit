import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/services/forgot_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';
import 'registration_screen.dart';
import 'package:my_aptechka/services/auth_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import '../styles.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _emailError = email.isEmpty ? 'Введите почту' : null;
      _passwordError = password.isEmpty ? 'Введите пароль' : null;
      _isLoading = false;
    });

    if (email.isNotEmpty && password.isNotEmpty) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      try {
        setState(() => _isLoading = true);

        await authService.login(email, password, userProvider);
        await DatabaseService.loadBackupFromServer(userProvider.userId!);

        final userData = await DatabaseService.getUserDetails(userProvider.userId!);
        if (userData != null) {
          userProvider.setName(userData['name'] as String?);
          userProvider.setSurname(userData['surname'] as String?);
          userProvider.setPhone(userData['phone'] as String?);
          userProvider.setSubscribe(userData['subscribe'] == 1);
          print('Updated UserProvider after server sync: $userData');
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
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
      } catch (e) {
        setState(() {
          _emailError = 'Неизвестная ошибка: $e';
        });
      } finally {
        setState(() => _isLoading = false);
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
                const SizedBox(height: 32),
                Text(
                  'Ваша почта и пароль',
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
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Забыли пароль?',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryBlue,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Войти'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
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