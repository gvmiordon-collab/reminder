import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'notification_config.dart';
import '../reminder/reminder_database.dart';
import '../reminder/reminder_model.dart';
import 'notification_ids.dart';
import 'notification_texts.dart';

const Duration _denseWindow = NotificationConfig.denseWindow;
const Duration _denseInterval = NotificationConfig.denseInterval;
/// 只有「有揀時間」嘅 reminder 先行 dense 層。冇揀時間嘅當日已經有
/// 9/12/15/18/21/23:55 六個通知(見 notification_plan.dart),
/// dense 再加就會 20:59–23:59 每 30 分鐘一次,太密(已同 Gordon 確認)。
bool _usesDense(Reminder r) => r.hasTime;

bool _inDenseWindow(Reminder r, DateTime now) {
  if (!_usesDense(r)) return false;
  final diff = r.effectiveDeadline.difference(now);
  return diff > Duration.zero && diff <= _denseWindow;
}

/// 主 isolate(reminder 有變動即時 refresh)同背景 isolate(alarm 準時
/// tick)都共用呢個 function,保證兩邊行為一致。
Future<void> refreshDenseNotification() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(
    settings: const InitializationSettings(android: androidInit),
  );

  final now = DateTime.now();
  final all = await ReminderDatabase.instance.getAllReminders();
  final active = all.where((r) => _inDenseWindow(r, now)).toList()
    ..sort((a, b) => a.effectiveDeadline.compareTo(b.effectiveDeadline));

  if (active.isEmpty) {
    await plugin.cancel(id: denseNotificationId);
    return;
  }

  /// 通知上面顯示嘅分鐘數:四捨五入,再吸附去最近嘅 30 分鐘倍數(差 3 分鐘內)。
  int _displayMinutes(Duration left) {
    final minutes = (left.inSeconds / 60).round();
    final step = _denseInterval.inMinutes;
    final snapped = (minutes / step).round() * step;
    if (snapped > 0 && (minutes - snapped).abs() <= 3) return snapped;
    return minutes < 0 ? 0 : minutes;
  }

  final target = active.first;
  final minutesLeft = _displayMinutes(target.effectiveDeadline.difference(now));
  final texts = NotificationTexts.denseMinutesLeft(
    target.title,
    minutesLeft < 0 ? 0 : minutesLeft,
  );

  await plugin.show(
    id: denseNotificationId,
    title: texts.title,
    body: texts.body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        denseChannelId,
        denseChannelName,
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true, // 唔畀 swipe / 「全部清除」清走
        autoCancel: false, // 撳通知本身都唔會消失
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            denseOkActionId,
            '確認',
            cancelNotification: true, // 撳「確認」先清走
          ),
        ],
      ),
    ),
    payload: 'reminder:${target.id}',
  );
}

/// 計「下一次應該叫醒 dense tick」嘅時刻,冇任何需要就返回 null。
///
/// 純計算,唔掂 alarm,方便理解同測試。規則:
/// - 已經喺 window 內嘅 reminder:下一次係「30 分鐘後」同「佢死線後 2 秒」
///   之中較早嗰個(死線後多醒一次,用嚟清走過期嘅「仲有 X 分鐘」通知)。
/// - 未入 window 嘅 reminder:下一次係佢入 window 嗰刻(死線 − 3 小時)。
/// - 所有 reminder 嘅結果取最早。
///
/// 重點:就算而家 window 內冇 reminder,只要之後仲有 reminder 會入
/// window,都會返回佢入 window 嘅時間——鏈唔會因為某一單完咗就斷。
DateTime? computeNextDenseTrigger(List<Reminder> reminders, DateTime now) {
  DateTime? next;
  for (final r in reminders) {
    if (!_usesDense(r)) continue;
    final deadline = r.effectiveDeadline;
    if (!deadline.isAfter(now)) continue;

    final diff = deadline.difference(now);
    final DateTime candidate;
    if (diff > _denseWindow) {
      // 未入 window:等到「死線 − 3 小時」
      candidate = deadline.subtract(_denseWindow);
    } else {
      // 已喺 window 內:揾下一個「死線 − 30 分鐘 × n」格位(嚴格喺而家之後);
      // 冇格位就係死線後 2 秒(清走過期通知)。
      final n = (diff.inSeconds - 1) ~/ _denseInterval.inSeconds;
      candidate = n >= 1
          ? deadline.subtract(_denseInterval * n)
          : deadline.add(const Duration(seconds: 2));
    }

    if (next == null || candidate.isBefore(next)) next = candidate;
  }
  return next;
}

/// 根據 [reminders] 排(或取消)全局唯一嗰條 dense alarm。
/// 主 isolate(reminder 有變動)同背景 isolate(tick 完之後)都用呢個,
/// 所以就算成日冇開過 app,鏈都會一直接落去。
Future<void> scheduleNextDenseAlarm(List<Reminder> reminders) async {
  if (!Platform.isAndroid) return;

  final next = computeNextDenseTrigger(reminders, DateTime.now());
  if (next == null) {
    await AndroidAlarmManager.cancel(denseAlarmId);
    return;
  }

  // 先試 exact;冇 exact alarm 權限或者失敗就退而求其次用 inexact,
  // 通知可能遲少少,但總好過成條鏈冇咗。
  var scheduled = false;
  try {
    scheduled = await AndroidAlarmManager.oneShotAt(
      next,
      denseAlarmId,
      denseTickCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  } catch (e) {
    debugPrint('Dense alarm(exact)排失敗,轉用 inexact: $e');
  }
  if (scheduled) return;

  try {
    await AndroidAlarmManager.oneShotAt(
      next,
      denseAlarmId,
      denseTickCallback,
      exact: false,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  } catch (e) {
    debugPrint('Dense alarm(inexact)都排失敗: $e');
  }
}

/// android_alarm_manager_plus 嘅 callback 一定要係 top-level function
/// (唔可以係 closure),仲要加呢個 pragma,唔係 release build 有機會
/// 俾 tree-shaking 拎走。
@pragma('vm:entry-point')
void denseTickCallback() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 兩步分開 try:就算 refresh 出事,都一定要試住排返下一次,
  // 唔可以令成條鏈因為一次失敗而斷。
  try {
    await refreshDenseNotification();
  } catch (e, st) {
    debugPrint('denseTick refresh 失敗: $e\n$st');
  }

  try {
    final all = await ReminderDatabase.instance.getAllReminders();
    await scheduleNextDenseAlarm(all);
  } catch (e, st) {
    debugPrint('denseTick 排下一次失敗: $e\n$st');
  }
}
