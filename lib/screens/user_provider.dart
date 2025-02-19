import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  void setUserId(String? id) {
    _userId = id;
    notifyListeners();
  }
}
