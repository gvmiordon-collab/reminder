import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../reminder/reminder_model.dart';
import 'notification_ids.dart';
import 'notification_plan.dart';
import 'dense_tick.dart';
import 'tab_notifier.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _milestoneChannelId = 'reminder_milestone';
  static const _milestoneChannelName = '備忘錄提醒';

  static const _prefExactAlarmPromptDismissed = 'exact_alarm_prompt_dismissed';

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
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // Gordon 已確認:撳咗通知一律跳去 list 頁。
        requestedTabIndex.value = 0;
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
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
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.requestNotificationsPermission() ?? false;
  }

  Future<bool> needsExactAlarmSettingsPrompt() async {
    if (!Platform.isAndroid) return false;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final canSchedule = await androidPlugin?.canScheduleExactNotifications();
    return canSchedule == false;
  }

  Future<void> openExactAlarmSettings() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  // ===== 「準時提醒」權限 dialog 嘅「已經問過」記錄(fix E)=====
  // 撳「遲啲先」之後記低,之後開 app 唔再彈。撳「去開」唔記——如果佢返嚟
  // 之後仲未開到權限,下次開 app 會再問一次。

  Future<bool> isExactAlarmPromptDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefExactAlarmPromptDismissed) ?? false;
  }

  Future<void> setExactAlarmPromptDismissed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefExactAlarmPromptDismissed, value);
  }

  /// 有 exact alarm 權限就用 exact,冇就即刻用 inexact(通知可能遲幾分鐘,
  /// 但唔會 throw)。iOS 冇呢個概念,參數會被忽略。
  Future<AndroidScheduleMode> _pickScheduleMode() async {
    if (!Platform.isAndroid) return AndroidScheduleMode.exactAllowWhileIdle;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final canExact = await androidPlugin?.canScheduleExactNotifications();
    return canExact == false
        ? AndroidScheduleMode.inexactAllowWhileIdle
        : AndroidScheduleMode.exactAllowWhileIdle;
  }

  /// 排一個 milestone 通知。exact 失敗會自動退到 inexact,兩個都失敗就
  /// 淨係 log,絕對唔 throw——通知排唔到唔可以搞到 add/load 卡死(fix B)。
  Future<void> _scheduleOne({
    required int id,
    required ({String title, String body}) texts,
    required DateTime fireTime,
    required String payload,
    required AndroidScheduleMode mode,
  }) async {
    Future<void> attempt(AndroidScheduleMode m) {
      return _plugin.zonedSchedule(
        id: id,
        title: texts.title,
        body: texts.body,
        scheduledDate: tz.TZDateTime.from(fireTime, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _milestoneChannelId,
            _milestoneChannelName,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: m,
        payload: payload,
      );
    }

    try {
      await attempt(mode);
      return;
    } catch (e) {
      debugPrint('排通知失敗(id=$id, mode=$mode): $e');
    }

    if (mode == AndroidScheduleMode.inexactAllowWhileIdle) return;
    try {
      await attempt(AndroidScheduleMode.inexactAllowWhileIdle);
    } catch (e) {
      debugPrint('排通知(inexact fallback)都失敗(id=$id): $e');
    }
  }

  /// 幫一則 reminder 排晒 milestone 通知,已過咗嘅時間點自動跳過。
  /// 排咩、幾時彈、寫咩字,全部喺 notification_plan.dart
  /// ([buildMilestonePlan]),有時間同冇時間嘅 reminder 規則唔同。
  /// Dense tier 唔喺呢度處理,見 [recomputeDenseSchedule]。
  Future<void> scheduleForReminder(Reminder reminder) async {
    if (reminder.id == null) return;

    // 先清晒呢則 reminder 所有 tier:改咗期、或者由有時間改做冇時間
    // (兩邊用嘅 tier 唔同),都唔會剩低幽靈通知。
    await cancelForReminder(reminder.id!);

    final now = DateTime.now();
    final mode = await _pickScheduleMode();

    for (final item in buildMilestonePlan(reminder)) {
      if (!item.fireTime.isAfter(now)) continue; // 已經過咗嘅時間點,唔使再排

      await _scheduleOne(
        id: NotificationTier.milestoneNotificationId(reminder.id!, item.tier),
        texts: item.texts,
        fireTime: item.fireTime,
        payload: 'reminder:${reminder.id}',
        mode: mode,
      );
    }
  }

  Future<void> cancelForReminder(int reminderId) async {
    for (final tier in NotificationTier.all) {
      await _plugin.cancel(id: NotificationTier.milestoneNotificationId(reminderId, tier));
    }
  }

  /// Dense tier(得 Android 有)嘅總指揮:即刻 refresh 返而家嗰個 dense
  /// notification,再幫「下一個需要醒嘅時刻」排 alarm。
  /// 「下一個時刻」點計、alarm 點排,全部喺 dense_tick.dart
  /// ([scheduleNextDenseAlarm]),因為背景 isolate 每次 tick 完都要用同一套邏輯。
  Future<void> recomputeDenseSchedule(List<Reminder> reminders) async {
    if (!Platform.isAndroid) return;

    await refreshDenseNotification();
    await scheduleNextDenseAlarm(reminders);
  }
}