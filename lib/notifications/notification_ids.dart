/// 通知 id / channel 呢啲常數,主 app isolate 同 alarm 背景 callback
/// 兩邊都會 import,獨立開一個檔案方便共用,唔好加任何 UI/Provider 依賴。
class NotificationTier {
  static const int day7 = 0;
  static const int day3 = 1;
  static const int day1 = 2;
  static const int dayOf = 3; // 死線當日 00:05

  static int milestoneNotificationId(int reminderId, int tier) =>
      reminderId * 10 + tier;
}

/// Dense tier 淨係一個「浮動」通知,代表「而家最早死線嗰單」,
/// 唔綁死邊個 reminder,所以用固定 id,新內容直接覆蓋舊嘅。
const int denseNotificationId = 999999;

/// 驅動 dense tick 嘅 alarm id(android_alarm_manager_plus 用),
/// 全局淨係一個,保證唔會同時有兩條「歸納」邏輯running。
const int denseAlarmId = 888888;

const String denseChannelId = 'reminder_dense';
const String denseChannelName = '備忘錄倒數提醒（3小時內）';