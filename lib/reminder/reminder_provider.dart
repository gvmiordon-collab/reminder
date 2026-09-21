import 'package:flutter/foundation.dart';
import '../notifications/notification_service.dart';
import 'reminder_database.dart';
import 'reminder_model.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderDatabase _db = ReminderDatabase.instance;

  List<Reminder> _reminders = [];
  bool isLoading = true;

  List<Reminder> get reminders => _reminders;

  /// 所有通知相關操作都經呢度包一層:通知排唔到(例如冇權限、系統限制)
  /// 只係 log,絕對唔可以令 load / add / edit / remove 中途斷咗,
  /// 令 list 轉圈或者畫面唔 refresh。
  Future<void> _safely(String label, Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      debugPrint('Notification 操作失敗($label): $e\n$st');
    }
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final all = await _db.getAllReminders();

      final overdue = all.where((r) => r.isOverdue);
      for (final r in overdue) {
        if (r.id != null) {
          await _db.deleteReminder(r.id!);
          await _safely(
            'cancel overdue',
                () => NotificationService.instance.cancelForReminder(r.id!),
          );
        }
      }

      _reminders = all.where((r) => !r.isOverdue).toList();

      // 每次開機都重新排晒全部 active reminder 嘅通知——就算之前啲通知因為
      // 裝置重開/App 更新/重裝甩咗,呢度都會自動補返晒(冪等操作)。
      for (final r in _reminders) {
        await _safely(
          'reschedule ${r.id}',
              () => NotificationService.instance.scheduleForReminder(r),
        );
      }
      await _safely(
        'recompute dense',
            () => NotificationService.instance.recomputeDenseSchedule(_reminders),
      );
    } finally {
      // 無論中途發生咩事,都一定要放走 loading 狀態,list 先唔會永遠轉圈。
      isLoading = false;
      notifyListeners();
    }
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

    await _safely(
      'schedule new',
          () => NotificationService.instance.scheduleForReminder(inserted),
    );
    await _safely(
      'recompute dense',
          () => NotificationService.instance.recomputeDenseSchedule(_reminders),
    );

    notifyListeners();
  }

  /// 編輯已有 reminder:title/dueDate/hasTime 可以改,createdAt 唔變,
  /// updatedAt 更新做而家。改完要 cancel 舊通知、用新資料重新排過,
  /// 再 recompute 一次 dense schedule(同 add/remove 嗰套邏輯一致)。
  Future<void> editReminder({
    required int id,
    required String title,
    required DateTime dueDate,
    required bool hasTime,
  }) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index == -1) return; // 保險:揾唔到就乜都唔做

    final existing = _reminders[index];
    final updated = Reminder(
      id: id,
      title: title,
      dueDate: dueDate,
      hasTime: hasTime,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    await _db.updateReminder(updated);
    await _safely(
      'cancel old',
          () => NotificationService.instance.cancelForReminder(id),
    );

    _reminders = [
      for (final r in _reminders) if (r.id == id) updated else r,
    ]..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    await _safely(
      'schedule edited',
          () => NotificationService.instance.scheduleForReminder(updated),
    );
    await _safely(
      'recompute dense',
          () => NotificationService.instance.recomputeDenseSchedule(_reminders),
    );

    notifyListeners();
  }

  /// check 同 delete 兩個掣底層都係呢個 function(完成 = 刪除)
  Future<void> removeReminder(int id) async {
    await _db.deleteReminder(id);
    await _safely(
      'cancel removed',
          () => NotificationService.instance.cancelForReminder(id),
    );
    _reminders = _reminders.where((r) => r.id != id).toList();
    await _safely(
      'recompute dense',
          () => NotificationService.instance.recomputeDenseSchedule(_reminders),
    );
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