import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_aptechka/screens/login_screen.dart';
import 'package:my_aptechka/screens/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  const WelcomeScreen({super.key, required this.isLoggedIn});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorTween;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _colorTween = ColorTween(
      begin: const Color.fromARGB(255, 72, 129, 252),
      end: const Color(0xFF0A47A1),
    ).animate(_controller);

    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              widget.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_colorTween.value!, const Color(0xFF197FF2)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Image.asset('assets/title.png',
                            width: 200, height: 200),
                        const SizedBox(height: 20),
                        const Text(
                          'Позаботься о себе\nи своих близких',
                          style: TextStyle(
                              fontFamily: 'Commissioner',
                              fontSize: 20,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
