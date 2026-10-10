import 'package:intl/intl.dart';

import '../reminder/reminder_model.dart';
import 'notification_config.dart';
import 'notification_ids.dart';
import 'notification_texts.dart';

/// 一個「計劃好」嘅通知:邊個 tier、幾時彈、寫咩字,
/// 以及幾耐之後會被下一個覆蓋(null = 企到你撳「確認」)。
typedef PlannedNotification = ({
int tier,
DateTime fireTime,
({String title, String body}) texts,
Duration? replaceAfter,
});

typedef _Item = ({int tier, DateTime fire});

/// 計出一則 reminder 所有 milestone 通知(過期嘅由 caller 跳過)。
/// 時間全部喺 notification_config.dart。規則:
/// - 7/3/1 日前:有時間/冇時間一樣,嗰日 advanceTimes 每個時間各一個。
/// - 有時間 reminder 死線當日:冇 milestone,只有 dense 倒數(dense_tick.dart)。
/// - 冇時間 reminder 死線當日:dateOnlyDayOfTimes 每個時間各一個。
/// 同一日內,先彈嗰個會喺下一個彈出嗰刻被覆蓋;最後一個企到你撳「確認」。
List<PlannedNotification> buildMilestonePlan(Reminder r) {
  assert(NotificationConfig.advanceDays.length <= 5, 'advanceDays 最多 5 個');
  assert(NotificationConfig.advanceTimes.length <= 5, 'advanceTimes 最多 5 個');
  assert(NotificationConfig.dateOnlyDayOfTimes.length <= 50,
  'dateOnlyDayOfTimes 最多 50 個');

  final d = r.dueDate;
  final deadline = r.effectiveDeadline;

  // 用 DateTime(y, m, d - n, ...) 而唔係 subtract(Duration),
  // 咁「幾點」永遠準確,唔會受日光節約等影響。
  DateTime at(int daysBefore, int hour, int minute) =>
      DateTime(d.year, d.month, d.day - daysBefore, hour, minute);

  final timeText = r.hasTime ? DateFormat('H:mm').format(d) : null;
  final plan = <PlannedNotification>[];

  // 將「同一日」嘅一組通知加入 plan:按時間排好,死線之後嘅丟棄,
  // 先彈嗰個被下一個覆蓋。
  void addDay(List<_Item> items, ({String title, String body}) texts) {
    final valid = items.where((e) => e.fire.isBefore(deadline)).toList()
      ..sort((a, b) => a.fire.compareTo(b.fire));
    for (var i = 0; i < valid.length; i++) {
      final isLast = i == valid.length - 1;
      plan.add((
      tier: valid[i].tier,
      fireTime: valid[i].fire,
      texts: texts,
      replaceAfter:
      isLast ? null : valid[i + 1].fire.difference(valid[i].fire),
      ));
    }
  }

  // ===== 7 / 3 / 1 日前 =====
  final days = NotificationConfig.advanceDays;
  final times = NotificationConfig.advanceTimes;
  for (var di = 0; di < days.length; di++) {
    final n = days[di];
    final texts = n == 1
        ? NotificationTexts.tomorrow(r.title, timeText: timeText)
        : NotificationTexts.countdown(r.title, n);
    addDay([
      for (var ti = 0; ti < times.length; ti++)
        (
        tier: NotificationTier.advance(di, ti),
        fire: at(n, times[ti].hour, times[ti].minute),
        ),
    ], texts);
  }

  // ===== 冇時間 reminder:死線當日 =====
  if (!r.hasTime) {
    final slots = NotificationConfig.dateOnlyDayOfTimes;
    addDay([
      for (var i = 0; i < slots.length; i++)
        (
        tier: NotificationTier.dayOf(i),
        fire: at(0, slots[i].hour, slots[i].minute),
        ),
    ], NotificationTexts.dayOf(r.title));
  }

  return plan;
}