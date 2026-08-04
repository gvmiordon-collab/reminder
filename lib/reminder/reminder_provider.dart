import 'package:flutter/foundation.dart';
import 'reminder_database.dart';
import 'reminder_model.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderDatabase _db = ReminderDatabase.instance;

  List<Reminder> _reminders = [];
  bool isLoading = true;

  List<Reminder> get reminders => _reminders;

  /// App 開機 / Provider 建立嗰陣 call 一次:讀資料 + purge overdue(MVP,已確認唔加 timer)
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    final all = await _db.getAllReminders();

    final overdue = all.where((r) => r.isOverdue);
    for (final r in overdue) {
      if (r.id != null) await _db.deleteReminder(r.id!);
    }

    _reminders = all.where((r) => !r.isOverdue).toList();
    isLoading = false;
    notifyListeners();
  }

  Future<void> addReminder({
    required String title,
    required DateTime dueDate,
    required bool hasTime,
  }) async {
    final now = DateTime.now();
    final inserted = await _db.insertReminder(Reminder(
      title: title,
      dueDate: dueDate,
      hasTime: hasTime,
      createdAt: now,
      updatedAt: now,
    ));
    _reminders = [..._reminders, inserted]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    notifyListeners();
  }

  /// check 同 delete 兩個掣底層都係呢個 function(已確認:完成 = 刪除)
  Future<void> removeReminder(int id) async {
    await _db.deleteReminder(id);
    _reminders = _reminders.where((r) => r.id != id).toList();
    notifyListeners();
  }

  // reminder_provider.dart 新增

  /// 俾 Calendar 畫紫色 highlight 用：淨日期(冇時間)嘅 set
  Set<DateTime> get datesWithReminders {
    return _reminders
        .map((r) => DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day))
        .toSet();
  }

  /// 俾 bottom sheet 用：攞返指定一日嘅全部 reminder，跟 dueDate 排好序
  List<Reminder> remindersOnDay(DateTime day) {
    return _reminders.where((r) =>
    r.dueDate.year == day.year &&
        r.dueDate.month == day.month &&
        r.dueDate.day == day.day).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }




}