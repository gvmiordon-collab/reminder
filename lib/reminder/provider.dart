import 'package:flutter/material.dart';

class ReminderProvider extends ChangeNotifier {
  final List<Map<String, String>> _reminders = [];
  List<Map<String, String>> get reminders => _reminders;

  void addReminder(String todo, String date) {
    _reminders.add({'todo': todo, 'date': date});
    notifyListeners();
  }

  void removeReminder(int index) {
    _reminders.removeAt(index);
    notifyListeners();   // ✅ 一樣要喺 state 改完之後先call
  }

  void finishReminder(int index) {
    _reminders.removeAt(index);
    notifyListeners();
  }



}


