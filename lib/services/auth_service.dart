import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_aptechka/screens/user_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Проверка статуса входа
  Future<bool> isLoggedIn(UserProvider userProvider) async {
    User? user = _auth.currentUser;
    if (user != null) {
      userProvider.setUserId(user.uid);
      userProvider.setEmail(user.email ?? '');
      print('User is logged in: ${user.uid}');
      return true;
    }
    print('No user logged in');
    return false;
  }

  // Выход из системы
  Future<void> logout(UserProvider userProvider) async {
    await _auth.signOut();
    userProvider.setUserId(null);
    userProvider.setEmail('');
    await _secureStorage.delete(key: 'user_id');
    print('User logged out');
  }

  // Метод для авторизации (будет использоваться в LoginScreen)
  Future<void> login(String email, String password, UserProvider userProvider) async {
  try {
    print('Attempting to log in with email: $email');
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    print('Login successful. User ID: ${userCredential.user?.uid}, Email: ${userCredential.user?.email}');
    userProvider.setUserId(userCredential.user!.uid);
    userProvider.setEmail(userCredential.user!.email ?? '');
  } on FirebaseAuthException catch (e) {
    print('FirebaseAuthException: ${e.code} - ${e.message}');
    rethrow;
  } catch (e, stackTrace) {
    print('Unexpected error during login: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<void> register(String email, String password, UserProvider userProvider) async {
  try {
    print('Attempting to register with email: $email');
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    print('Registration successful. User ID: ${userCredential.user?.uid}, Email: ${userCredential.user?.email}');
    userProvider.setUserId(userCredential.user!.uid);
    userProvider.setEmail(userCredential.user!.email ?? '');
  } on FirebaseAuthException catch (e) {
    print('FirebaseAuthException: ${e.code} - ${e.message}');
    rethrow;
  } catch (e, stackTrace) {
    print('Unexpected error during registration: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}
}