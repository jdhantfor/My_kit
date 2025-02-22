import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _name;
  String? _surname;
  String? _email;
  String? _password;
  String? _phone;

  String? get userId => _userId;
  String? get name => _name;
  String? get surname => _surname;
  String? get email => _email;
  String? get password => _password;
  String? get phone => _phone;

  void setUserId(String? id) {
    _userId = id;
    notifyListeners();
  }

  void setName(String name) {
    _name = name;
    notifyListeners();
  }

  void setSurname(String surname) {
    _surname = surname;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  void setPhone(String phone) {
    _phone = phone;
    notifyListeners();
  }
}
