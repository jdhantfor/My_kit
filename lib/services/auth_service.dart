import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:my_aptechka/screens/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Проверка статуса входа
  Future<bool> isLoggedIn(UserProvider userProvider) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload(); // Обновляем состояние пользователя
        user = _auth.currentUser; // Получаем обновлённого пользователя
        userProvider.setUserId(user?.uid);
        userProvider.setEmail(user?.email ?? '');
        // Загружаем остальные данные пользователя
        await _loadUserDataIntoProvider(userProvider, user!.uid);
        print('User is logged in: ${user.uid}');
        return true;
      }
      print('No user logged in');
      return false;
    } catch (e, stackTrace) {
      print('Error checking login status: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Выход из системы
  Future<void> logout(UserProvider userProvider) async {
    try {
      await _auth.signOut();
      userProvider.setUserId(null);
      userProvider.setEmail('');
      userProvider.setName(null);
      userProvider.setSurname(null);
      userProvider.setPhone(null);
      userProvider.setSubscribe(false);
      await _secureStorage.delete(key: 'user_id');
      print('User logged out');
    } catch (e, stackTrace) {
      print('Error during logout: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Вход в систему
  Future<void> login(
    String email,
    String password,
    UserProvider userProvider,
  ) async {
    try {
      print('Attempting to log in with email: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(
          'Login successful. User ID: ${userCredential.user?.uid}, Email: ${userCredential.user?.email}');

      // Устанавливаем базовые данные
      userProvider.setUserId(userCredential.user!.uid);
      userProvider.setEmail(userCredential.user!.email ?? '');

      // Проверяем подтверждение email
      await userCredential.user!.reload();
      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Пожалуйста, подтвердите ваш email.',
        );
      }

      // Загружаем все данные пользователя в провайдер
      await _loadUserDataIntoProvider(userProvider, userCredential.user!.uid);

      // Сохраняем user_id в безопасное хранилище
      await _secureStorage.write(
          key: 'user_id', value: userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('Unexpected error during login: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Регистрация
  Future<void> register(
    String email,
    String password,
    UserProvider userProvider,
  ) async {
    try {
      print('Attempting to register with email: $email');
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(
          'Registration successful. User ID: ${userCredential.user?.uid}, Email: ${userCredential.user?.email}');

      // Устанавливаем базовые данные
      userProvider.setUserId(userCredential.user!.uid);
      userProvider.setEmail(userCredential.user!.email ?? '');

      // Создаём запись в локальной базе
      await DatabaseService.updateUserDetails(
        userCredential.user!.uid,
        email: userCredential.user!.email,
      );

      // Загружаем данные в провайдер (на случай, если они уже есть)
      await _loadUserDataIntoProvider(userProvider, userCredential.user!.uid);

      // Сохраняем user_id в безопасное хранилище
      await _secureStorage.write(
          key: 'user_id', value: userCredential.user!.uid);

      // Отправляем письмо с подтверждением
      await userCredential.user!.sendEmailVerification();
      print('Verification email sent to: $email');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('Unexpected error during registration: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Вспомогательный метод для загрузки данных пользователя в провайдер
  Future<void> _loadUserDataIntoProvider(
      UserProvider userProvider, String userId) async {
    final userData = await DatabaseService.getUserDetails(userId);
    if (userData != null) {
      userProvider.setName(userData['name'] as String?);
      userProvider.setSurname(userData['surname'] as String?);
      userProvider.setPhone(userData['phone'] as String?);
      userProvider.setSubscribe(userData['subscribe'] == 1);
      print('Loaded user data into provider: $userData');
    } else {
      print('No user data found in local database for userId: $userId');
    }
  }

  // Отправка письма на сброс пароля
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('Attempting to send password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      print('Unexpected error during password reset: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Проверка статуса подтверждения email
  Future<bool> isEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;
        return user?.emailVerified ?? false;
      }
      return false;
    } catch (e, stackTrace) {
      print('Error checking email verification: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Переотправка письма с подтверждением
  Future<void> resendVerificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        user = _auth.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          print('Verification email resent to: ${user.email}');
        } else {
          throw Exception('Email already verified or user not found');
        }
      } else {
        throw Exception('No user logged in to resend verification email');
      }
    } catch (e, stackTrace) {
      print('Error resending verification email: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}