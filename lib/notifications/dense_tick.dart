import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../reminder/reminder_database.dart';
import '../reminder/reminder_model.dart';
import 'notification_ids.dart';
import 'notification_texts.dart';

DateTime _effectiveDeadline(Reminder r) {
  if (r.hasTime) return r.dueDate;
  return DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day, 23, 59, 59);
}

bool _inDenseWindow(Reminder r, DateTime now) {
  final diff = _effectiveDeadline(r).difference(now);
  return diff > Duration.zero && diff <= const Duration(hours: 3);
}

/// 主 isolate(reminder 有變動即時 refresh)同背景 isolate(alarm 準時
/// tick)都共用呢個 function,保證兩邊行為一致。
Future<void> refreshDenseNotification() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: androidInit));

  final now = DateTime.now();
  final all = await ReminderDatabase.instance.getAllReminders();
  final active = all.where((r) => _inDenseWindow(r, now)).toList()
    ..sort((a, b) => _effectiveDeadline(a).compareTo(_effectiveDeadline(b)));

  if (active.isEmpty) {
    await plugin.cancel(denseNotificationId);
    return;
  }

  final target = active.first;
  final minutesLeft = _effectiveDeadline(target).difference(now).inMinutes;
  final texts = NotificationTexts.denseMinutesLeft(
    target.title,
    minutesLeft < 0 ? 0 : minutesLeft,
  );

  await plugin.show(
    denseNotificationId,
    texts.title,
    texts.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        denseChannelId,
        denseChannelName,
        importance: Importance.max,
        priority: Priority.high,
        // Gordon 已確認:dense tier 次次都要震/出聲,唔好加 onlyAlertOnce。
      ),
    ),
    payload: 'reminder:${target.id}',
  );
}

/// android_alarm_manager_plus 嘅 callback 一定要係 top-level function
/// (唔可以係 closure),仲要加呢個 pragma,唔係 release build 有機會
/// 俾 tree-shaking 拎走。
@pragma('vm:entry-point')
void denseTickCallback() async {
  WidgetsFlutterBinding.ensureInitialized();

  await refreshDenseNotification();

  final now = DateTime.now();
  final all = await ReminderDatabase.instance.getAllReminders();
  final stillActive = all.any((r) => _inDenseWindow(r, now));

  if (stillActive && Platform.isAndroid) {
    await AndroidAlarmManager.oneShotAt(
      now.add(const Duration(minutes: 30)),
      denseAlarmId,
      denseTickCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }
}