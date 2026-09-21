import 'package:intl/intl.dart';

import '../reminder/reminder_model.dart';
import 'notification_ids.dart';
import 'notification_texts.dart';

/// 一個「計劃好」嘅通知:邊個 tier、幾時彈、寫咩字。
typedef PlannedNotification = ({
int tier,
DateTime fireTime,
({String title, String body}) texts,
});

/// 冇揀時間嘅 reminder,當日 6 個通知嘅時間(已同 Gordon 確認)。
/// 想改時間淨係改呢個 list。
const List<({int tier, int hour, int minute})> _dateOnlyDayOfSlots = [
  (tier: NotificationTier.dayOf0900, hour: 9, minute: 0),
  (tier: NotificationTier.dayOf1200, hour: 12, minute: 0),
  (tier: NotificationTier.dayOf1500, hour: 15, minute: 0),
  (tier: NotificationTier.dayOf1800, hour: 18, minute: 0),
  (tier: NotificationTier.dayOf2100, hour: 21, minute: 0),
  (tier: NotificationTier.dayOf2355, hour: 23, minute: 55),
];

/// 7/3/1 日前嗰三個通知,喺冇揀時間嘅 reminder 用呢個鐘數彈(已同 Gordon 確認)。
const int _dateOnlyAdvanceHour = 21;

/// 計出一則 reminder 所有 milestone 通知(未理過唔過期,過期嘅由 caller 跳過)。
///
/// - 有揀時間:死線 −7 / −3 / −1 日同一鐘數,加當日 00:05 一個。
/// - 冇揀時間:7/3/1 日前嘅 21:00,加當日 9:00 / 12:00 / 15:00 / 18:00 /
///   21:00 / 23:55 六個,取代原本嘅 00:05。
///
/// 純計算,唔掂 plugin,方便日後改規則或者寫 test。
List<PlannedNotification> buildMilestonePlan(Reminder r) {
  return r.hasTime ? _timedPlan(r) : _dateOnlyPlan(r);
}

List<PlannedNotification> _timedPlan(Reminder r) {
  final due = r.dueDate;
  final timeText = DateFormat('H:mm').format(due);

  return [
    (
    tier: NotificationTier.day7,
    fireTime: due.subtract(const Duration(days: 7)),
    texts: NotificationTexts.countdown(r.title, 7),
    ),
    (
    tier: NotificationTier.day3,
    fireTime: due.subtract(const Duration(days: 3)),
    texts: NotificationTexts.countdown(r.title, 3),
    ),
    (
    tier: NotificationTier.day1,
    fireTime: due.subtract(const Duration(days: 1)),
    texts: NotificationTexts.tomorrow(r.title, timeText: timeText),
    ),
    (
    tier: NotificationTier.dayOf,
    fireTime: DateTime(due.year, due.month, due.day, 0, 5),
    texts: NotificationTexts.dayOf(r.title, timeText: timeText),
    ),
  ];
}

List<PlannedNotification> _dateOnlyPlan(Reminder r) {
  final d = r.dueDate;

  // 用 DateTime(y, m, d - n, ...) 而唔係 subtract(Duration),
  // 咁「幾點」永遠準確,唔會受日光節約等影響。
  DateTime at(int daysBefore, int hour, int minute) =>
      DateTime(d.year, d.month, d.day - daysBefore, hour, minute);

  final plan = <PlannedNotification>[
    (
    tier: NotificationTier.day7,
    fireTime: at(7, _dateOnlyAdvanceHour, 0),
    texts: NotificationTexts.countdown(r.title, 7),
    ),
    (
    tier: NotificationTier.day3,
    fireTime: at(3, _dateOnlyAdvanceHour, 0),
    texts: NotificationTexts.countdown(r.title, 3),
    ),
    (
    tier: NotificationTier.day1,
    fireTime: at(1, _dateOnlyAdvanceHour, 0),
    texts: NotificationTexts.tomorrow(r.title),
    ),
  ];

  final dayOfTexts = NotificationTexts.dayOf(r.title);
  for (final slot in _dateOnlyDayOfSlots) {
    plan.add((
    tier: slot.tier,
    fireTime: at(0, slot.hour, slot.minute),
    texts: dayOfTexts,
    ));
  }

  return plan;
}