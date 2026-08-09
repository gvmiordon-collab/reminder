import 'package:flutter/foundation.dart';
import '../notifications/notification_service.dart';
import 'reminder_database.dart';
import 'reminder_model.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderDatabase _db = ReminderDatabase.instance;

  List<Reminder> _reminders = [];
  bool isLoading = true;

  List<Reminder> get reminders => _reminders;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    final all = await _db.getAllReminders();

    final overdue = all.where((r) => r.isOverdue);
    for (final r in overdue) {
      if (r.id != null) {
        await _db.deleteReminder(r.id!);
        await NotificationService.instance.cancelForReminder(r.id!);
      }
    }

    _reminders = all.where((r) => !r.isOverdue).toList();

    // 每次開機都重新排晒全部 active reminder 嘅通知——就算之前啲通知因為
    // 裝置重開/App 更新/重裝甩咗,呢度都會自動補返晒(冪等操作)。
    for (final r in _reminders) {
      await NotificationService.instance.scheduleForReminder(r);
    }
    await NotificationService.instance.recomputeDenseSchedule(_reminders);

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

    await NotificationService.instance.scheduleForReminder(inserted);
    await NotificationService.instance.recomputeDenseSchedule(_reminders);

    notifyListeners();
  }

  /// check 同 delete 兩個掣底層都係呢個 function(完成 = 刪除)
  Future<void> removeReminder(int id) async {
    await _db.deleteReminder(id);
    await NotificationService.instance.cancelForReminder(id);
    _reminders = _reminders.where((r) => r.id != id).toList();
    await NotificationService.instance.recomputeDenseSchedule(_reminders);
    notifyListeners();
  }

  Set<DateTime> get datesWithReminders {
    return _reminders
        .map((r) => DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day))
        .toSet();
  }

  List<Reminder> remindersOnDay(DateTime day) {
    return _reminders.where((r) =>
    r.dueDate.year == day.year &&
        r.dueDate.month == day.month &&
        r.dueDate.day == day.day).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }
}