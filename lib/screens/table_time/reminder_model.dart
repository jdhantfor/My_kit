import 'package:flutter/material.dart';

class ReminderModel extends ChangeNotifier {
  List<Map<String, dynamic>> reminders = [];

  void addReminder(Map<String, dynamic> reminder) {
    reminders.add(reminder);
    notifyListeners(); // Уведомляем слушателей об изменении
  }

  void removeReminder(int index) {
    if (index >= 0 && index < reminders.length) {
      reminders.removeAt(index);
      notifyListeners(); // Уведомляем слушателей об изменении
    }
  }

  void updateReminder(Map<String, dynamic> reminder) {}
}
