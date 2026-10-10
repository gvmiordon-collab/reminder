/// ★ 所有通知「幾時彈」都喺呢個檔案改,其他檔案唔使掂 ★
///
/// 改完 → 重新 build / 裝 APK → 第一次開 app 會自動清走舊排程、
/// 用新時間重排。(呢一次會清走已經彈出但未撳「確認」嘅通知。)
class NotificationConfig {
  NotificationConfig._();

  // ===== 7 / 3 / 1 日前(有時間、冇時間一樣)=====

  /// 死線前幾多日要通知。最多 5 個。
  static const List<int> advanceDays = [7, 3, 1];

  /// 嗰一日幾點彈,(時, 分),24 小時制。最多 5 個,次序隨意。
  static const List<({int hour, int minute})> advanceTimes = [
    (hour: 9, minute: 0),
    (hour: 21, minute: 0),
  ];

  // ===== 冇揀時間嘅 reminder:死線當日 =====

  /// 當日幾點彈,(時, 分)。最多 50 個,次序隨意。
  static const List<({int hour, int minute})> dateOnlyDayOfTimes = [
    (hour: 9, minute: 0),
    (hour: 12, minute: 0),
    (hour: 15, minute: 0),
    (hour: 18, minute: 0),
    (hour: 21, minute: 0),
    (hour: 23, minute: 55), // 想改 23:00 就改呢行
  ];

  // ===== 有揀時間嘅 reminder:死線前倒數 =====

  /// 死線前幾耐開始倒數。
  static const Duration denseWindow = Duration(hours: 3);

  /// 倒數通知間隔(建議唔好少過 10 分鐘)。
  static const Duration denseInterval = Duration(minutes: 30);

  /// 呢啲設定嘅「指紋」,改咗就會觸發一次自動清舊排程。
  static String get signature =>
      '$advanceDays|$advanceTimes|$dateOnlyDayOfTimes|$denseWindow|$denseInterval';
}