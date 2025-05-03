import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_aptechka/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/database_service.dart';
import 'services/auth_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';
import 'styles.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await DatabaseService.initializeDatabase();
    await NotificationService.initialize();
  } catch (e) {
    print('Initialization error: $e');
  }

  await _requestPermissions();

  final userProvider = UserProvider();
  final authService = AuthService();
  final isLoggedIn = await authService.isLoggedIn(userProvider);

  // Если пользователь залогинен, загружаем бэкап
  if (isLoggedIn) {
    await DatabaseService.loadBackupFromServer(userProvider.userId!);
  }

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

Future<void> _requestPermissions() async {
  final cameraStatus = await Permission.camera.request();
  if (!cameraStatus.isGranted) {
    print('Camera permission denied');
  }

  final photoStatus = await Permission.photos.request();
  if (!photoStatus.isGranted) {
    final storageStatus = await Permission.storage.request();
    if (!storageStatus.isGranted) {
      print('Photos/Storage permission denied');
    }
  }

  if (Platform.isAndroid) {
    final manageStorageStatus =
        await Permission.manageExternalStorage.request();
    if (!manageStorageStatus.isGranted) {
      print('Manage External Storage permission denied');
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        print('Storage permission denied');
      }
    }
  } else if (Platform.isIOS) {
    print('iOS: Photos permission handles file access');
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Аптечка',
      theme: AppTheme.theme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('ru', '')],
      home: WelcomeScreen(isLoggedIn: isLoggedIn),
      navigatorKey: NotificationService.navigatorKey,
      onGenerateRoute: (settings) {
        if (settings.name == '/today') {
          return MaterialPageRoute(builder: (context) => const HomeScreen());
        }
        return null;
      },
    );
  }
}
