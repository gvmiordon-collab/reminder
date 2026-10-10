import 'notification_config.dart';

/// 通知 id / channel 呢啲常數,主 app isolate 同 alarm 背景 callback
/// 兩邊都會 import,獨立開一個檔案方便共用,唔好加任何 UI/Provider 依賴。
class NotificationTier {
  NotificationTier._();

  /// 7/3/1 日前:tier = 日子序號 * 5 + 時間序號(0–24)
  static int advance(int dayIndex, int timeIndex) => dayIndex * 5 + timeIndex;

  /// 冇時間 reminder 當日:tier = 50 + 序號(50–99)
  static int dayOf(int slotIndex) => 50 + slotIndex;

  /// 而家 config 用到嘅全部 tier。cancel / 重排嗰陣一律清晒佢哋。
  static List<int> get all => [
    for (var d = 0; d < NotificationConfig.advanceDays.length; d++)
      for (var t = 0; t < NotificationConfig.advanceTimes.length; t++)
        advance(d, t),
    for (var i = 0; i < NotificationConfig.dateOnlyDayOfTimes.length; i++)
      dayOf(i),
  ];

  /// id = reminderId * 100 + tier
  static int milestoneNotificationId(int reminderId, int tier) =>
      reminderId * 100 + tier;
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
const String denseOkActionId = 'dense_ok';
