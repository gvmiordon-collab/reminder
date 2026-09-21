/// 通知 id / channel 呢啲常數,主 app isolate 同 alarm 背景 callback
/// 兩邊都會 import,獨立開一個檔案方便共用,唔好加任何 UI/Provider 依賴。
class NotificationTier {
  // ===== 有揀時間嘅 reminder =====
  static const int day7 = 0;
  static const int day3 = 1;
  static const int day1 = 2;
  static const int dayOf = 3; // 死線當日 00:05

  // ===== 冇揀時間(淨日期)嘅 reminder:當日 6 個通知 =====
  // (7/3/1 日前嗰三個仍然用 day7/day3/day1 呢三個 tier,淨係時間唔同。)
  static const int dayOf0900 = 4;
  static const int dayOf1200 = 5;
  static const int dayOf1500 = 6;
  static const int dayOf1800 = 7;
  static const int dayOf2100 = 8;
  static const int dayOf2355 = 9;

  /// 每則 reminder 全部 tier。cancel / 重排嗰陣一律清晒佢哋,
  /// 咁就算 reminder 由「有時間」改做「冇時間」(或者反過來)都唔會剩低幽靈通知。
  static const List<int> all = [
    day7, day3, day1, dayOf,
    dayOf0900, dayOf1200, dayOf1500, dayOf1800, dayOf2100, dayOf2355,
  ];

  /// id = reminderId * 10 + tier。tier 0–9 已經用晒十個位,
  /// 將來想再加 tier 就要改呢個編碼方式。
  static int milestoneNotificationId(int reminderId, int tier) =>
      reminderId * 10 + tier;
}

/// Dense tier 淨係一個「浮動」通知,代表「而家最早死線嗰單」,
/// 唔綁死邊個 reminder,所以用固定 id,新內容直接覆蓋舊嘅。
/// 用一個極大嘅數,避免撞到 reminderId * 10 + tier 嘅範圍。
const int denseNotificationId = 2000000000;

/// 驅動 dense tick 嘅 alarm id(android_alarm_manager_plus 用),
/// 全局淨係一個,保證唔會同時有兩條「歸納」邏輯running。
const int denseAlarmId = 888888;

const String denseChannelId = 'reminder_dense';
const String denseChannelName = '備忘錄倒數提醒（3小時內）';