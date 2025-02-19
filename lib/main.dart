import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Добавляем этот импорт
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_aptechka/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/database_service.dart';
import 'services/auth_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Заблокируем ориентацию экрана в портретном режиме
  Future.delayed(const Duration(milliseconds: 300), () async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  });

  try {
    await DatabaseService.initializeDatabase();
    await NotificationService.initialize();
  } catch (e) {
    print('Initialization error: $e');
  }
  ; // Инициализация службы уведомлений
  final userProvider = UserProvider();
  final authService = AuthService();
  // Проверяем статус входа
  final isLoggedIn = await authService.isLoggedIn(userProvider);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
        Provider.value(value: authService),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Аптечка',
      theme: ThemeData(
        fontFamily: 'Commissioner',
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.normal,
            fontSize: 14,
          ),
        ),
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            fontFamily: 'Commissioner',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ru', ''),
      ],
      home: WelcomeScreen(isLoggedIn: isLoggedIn),
      // Добавляем обработчик для уведомлений
      navigatorKey:
          NotificationService.navigatorKey, // Глобальный ключ навигатора
      onGenerateRoute: (settings) {
        if (settings.name == '/today') {
          return MaterialPageRoute(builder: (context) => HomeScreen());
        }
        return null;
      },
    );
  }
}
