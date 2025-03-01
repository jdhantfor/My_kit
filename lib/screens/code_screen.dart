import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class CodeScreen extends StatefulWidget {
  final String phone;

  const CodeScreen({
    super.key,
    required this.phone,
  });

  @override
  CodeScreenState createState() => CodeScreenState();
}

class CodeScreenState extends State<CodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _remainingTime = 30;
  late Timer _timer;
  bool _canResendCode = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _timer.cancel();
        setState(() {
          _canResendCode = true;
        });
      }
    });
  }

  // void _resendCode() async {
  //   final authService = Provider.of<AuthService>(context, listen: false);
  //  bool codeSent = await authService.sendVerificationCode(widget.phone);
  //  if (codeSent) {
  ////    setState(() {
  //    _remainingTime = 30;
  //     _canResendCode = false;
  //  });
  //  _startTimer();
  //  _showMessage('Новый код отправлен');
  //  } else {
  //  _showMessage('Ошибка отправки SMS');
  //  }
  //}

  void _verifyCode() async {
    String enteredCode =
        _controllers.map((controller) => controller.text).join();

    if (enteredCode.length == 4) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (await authService.verifyCode(
          widget.phone, enteredCode, userProvider)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showMessage('Неверный код');
      }
    } else {
      _showMessage('Пожалуйста, введите 4-значный код');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double cellWidth = (width - 3 * 4 - 50) / 4;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 68.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Введите код из СМС',
                      style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0B102B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Отправили код на номер ${widget.phone}',
                      style: TextStyle(
                          fontSize: 14.0, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: SizedBox(
                            width: cellWidth,
                            height: cellWidth,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.shade200,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                counterText: '',
                              ),
                              maxLength: 1,
                              style: const TextStyle(fontSize: 20),
                              onChanged: (value) {
                                if (value.length == 1 && index < 3) {
                                  FocusScope.of(context)
                                      .requestFocus(_focusNodes[index + 1]);
                                } else if (value.isEmpty && index > 0) {
                                  FocusScope.of(context)
                                      .requestFocus(_focusNodes[index - 1]);
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    _canResendCode
                        ? GestureDetector(
                            //onTap: _resendCode,
                            child: const Text(
                              'Отправить код повторно',
                              style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline),
                            ),
                          )
                        : Text(
                            'Отправить код повторно через $_remainingTime сек.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifyCode,
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(
                              const Color(0xFF197FF2)),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Подтвердить код',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension on AuthService {
  verifyCode(String phone, String enteredCode, UserProvider userProvider) {}
}
