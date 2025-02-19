import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_aptechka/screens/database_service.dart';
import 'package:my_aptechka/screens/user_provider.dart';
import 'package:provider/provider.dart';

class AuthService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> setLoggedIn(UserProvider userProvider) async {
    // Генерируем случайный user_id
    final String userId = DateTime.now().millisecondsSinceEpoch.toString();

    // Сохраняем user_id в SecureStorage
    await _secureStorage.write(key: 'user_id', value: userId);

    // Устанавливаем user_id в UserProvider
    userProvider.setUserId(userId);
  }

  Future<bool> isLoggedIn(UserProvider userProvider) async {
    final userId = await _secureStorage.read(key: 'user_id');
    if (userId != null) {
      userProvider.setUserId(userId);
      return true;
    }
    return false;
  }

  Future<void> logout(UserProvider userProvider) async {
    userProvider.setUserId(null);
    await _secureStorage.delete(key: 'user_id');
  }

  verifyCode(String phone, String enteredCode, UserProvider userProvider) {}
}
