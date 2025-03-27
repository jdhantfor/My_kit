import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_aptechka/screens/database_service.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _name;
  String? _surname;
  String? _phone;
  String? _email;
  String? _password;
  String? _avatarUrl;

  String? get userId => _userId;
  String? get name => _name;
  String? get surname => _surname;
  String? get phone => _phone;
  String? get email => _email;
  String? get password => _password;
  String? get avatarUrl => _avatarUrl;

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_userId != null) {
      // Подгружаем email из Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == _userId) {
        _email = user.email;
      }

      // Подгружаем остальные данные из локальной базы
      final userData = await DatabaseService.getUserDetails(_userId!);
      if (userData != null) {
        _name = userData['name'] as String?;
        _surname = userData['surname'] as String?;
        _phone = userData['phone'] as String?;
        _password = userData['password'] as String?;
        notifyListeners();
      }
    }
  }

  void setUserId(String? userId) {
    _userId = userId;
    _loadUserData();
    notifyListeners();
  }

  void setName(String? name) {
    _name = name;
    notifyListeners();
  }

  void setSurname(String? surname) {
    _surname = surname;
    notifyListeners();
  }

  void setPhone(String? phone) {
    _phone = phone;
    notifyListeners();
  }

  void setEmail(String? email) {
    _email = email;
    notifyListeners();
  }

  void setPassword(String? password) {
    _password = password;
    notifyListeners();
  }

  void setAvatarUrl(String? avatarUrl) {
    _avatarUrl = avatarUrl;
    notifyListeners();
  }
}
