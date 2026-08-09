import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:intl/intl.dart';

import '../reminder/reminder_model.dart';
import 'notification_ids.dart';
import 'notification_texts.dart';
import 'dense_tick.dart';
import 'tab_notifier.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _milestoneChannelId = 'reminder_milestone';
  static const _milestoneChannelName = '備忘錄提醒';

  /// main.dart 喺 runApp 之前 call。
  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final currentTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTz.identifier));
    } catch (_) {
      // 攞唔到本機時區就算,好過成個 app 冧咗(時間會用返 UTC,唔準但唔死)。
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // Gordon 已確認:撳咗通知一律跳去 list 頁。
        requestedTabIndex.value = 0;
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation
      AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        _milestoneChannelId,
        _milestoneChannelName,
        importance: Importance.max,
        description: '7日/3日/1日/當日 死線提醒',
      ));
      await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
        denseChannelId,
        denseChannelName,
        importance: Importance.max,
        description: '死線前3小時,每30分鐘一次',
      ));
      await AndroidAlarmManager.initialize();
    }

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation
      IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation
    AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.requestNotificationsPermission() ?? false;
  }

  Future<bool> needsExactAlarmSettingsPrompt() async {
    if (!Platform.isAndroid) return false;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation
    AndroidFlutterLocalNotificationsPlugin>();
    final canSchedule = await androidPlugin?.canScheduleExactNotifications();
    return canSchedule == false;
  }

  Future<void> openExactAlarmSettings() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation
    AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// 幫一則 reminder 排晒 4 個 milestone 通知,已過咗嘅時間點自動跳過。
  /// Dense tier 唔喺呢度處理,見 [recomputeDenseSchedule]。
  Future<void> scheduleForReminder(Reminder reminder) async {
    if (reminder.id == null) return;

    final deadline = _effectiveDeadline(reminder);
    final now = DateTime.now();
    final timeText = reminder.hasTime ? DateFormat('H:mm').format(reminder.dueDate) : null;

    final milestones = <int, DateTime>{
      NotificationTier.day7: deadline.subtract(const Duration(days: 7)),
      NotificationTier.day3: deadline.subtract(const Duration(days: 3)),
      NotificationTier.day1: deadline.subtract(const Duration(days: 1)),
      NotificationTier.dayOf: DateTime(
        reminder.dueDate.year, reminder.dueDate.month, reminder.dueDate.day, 0, 5,
      ),
    };

    for (final tier in milestones.keys) {
      final id = NotificationTier.milestoneNotificationId(reminder.id!, tier);
      await _plugin.cancel(id); // 先清舊嘅,改咗期都唔會有幽靈通知
      final fireTime = milestones[tier]!;
      if (!fireTime.isAfter(now)) continue; // 已經過咗嘅時間點,唔使再排

      final texts = switch (tier) {
        NotificationTier.day7 => NotificationTexts.countdown(reminder.title, 7),
        NotificationTier.day3 => NotificationTexts.countdown(reminder.title, 3),
        NotificationTier.day1 => NotificationTexts.tomorrow(reminder.title, timeText: timeText),
        _ => NotificationTexts.dayOf(reminder.title, timeText: timeText),
      };

      await _plugin.zonedSchedule(
        id,
        texts.title,
        texts.body,
        tz.TZDateTime.from(fireTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _milestoneChannelId,
            _milestoneChannelName,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder:${reminder.id}',
      );
    }
  }

  Future<void> cancelForReminder(int reminderId) async {
    for (final tier in [
      NotificationTier.day7,
      NotificationTier.day3,
      NotificationTier.day1,
      NotificationTier.dayOf,
    ]) {
      await _plugin.cancel(NotificationTier.milestoneNotificationId(reminderId, tier));
    }
  }

  /// Dense tier(得 Android 有)嘅總指揮:即刻 refresh 返而家嗰個 dense
  /// notification,再幫「下一個入 dense window 嘅時刻」排一個 alarm——
  /// 唔理 app 開唔開都會準時醒(見 dense_tick.dart)。
  Future<void> recomputeDenseSchedule(List<Reminder> reminders) async {
    if (!Platform.isAndroid) return;

    await refreshDenseNotification();

    final now = DateTime.now();
    DateTime? earliestTrigger;
    for (final r in reminders) {
      final deadline = _effectiveDeadline(r);
      if (!deadline.isAfter(now)) continue;
      final entryTime = deadline.subtract(const Duration(hours: 3));
      final trigger = entryTime.isAfter(now) ? entryTime : now.add(const Duration(seconds: 5));
      if (earliestTrigger == null || trigger.isBefore(earliestTrigger)) {
        earliestTrigger = trigger;
      }
    }

    if (earliestTrigger == null) {
      await AndroidAlarmManager.cancel(denseAlarmId);
      return;
    }

    await AndroidAlarmManager.oneShotAt(
      earliestTrigger,
      denseAlarmId,
      denseTickCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  /// 冇時間就當「嗰日 23:59:59」算死線,同 reminder_model.dart 嘅
  /// isOverdue 邏輯保持一致(已同 Gordon 確認)。
  DateTime _effectiveDeadline(Reminder reminder) {
    if (reminder.hasTime) return reminder.dueDate;
    return DateTime(
      reminder.dueDate.year, reminder.dueDate.month, reminder.dueDate.day, 23, 59, 59,
    );
  }
}