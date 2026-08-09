/// 產生每一層通知嘅 title/body。主 isolate(排 milestone)同背景
/// isolate(dense tick)共用呢個邏輯,保證文字格式一致,以後改格式
/// 淨係要改呢一個地方。
class NotificationTexts {
  /// 7 日 / 3 日前
  static ({String title, String body}) countdown(String reminderTitle, int daysBefore) {
    return (title: '$daysBefore天後', body: reminderTitle);
  }

  /// 1 日前:「聽日[時間]」,冇揀時間就淨係「聽日」
  static ({String title, String body}) tomorrow(String reminderTitle, {String? timeText}) {
    final title = timeText == null ? '聽日' : '聽日 $timeText';
    return (title: title, body: reminderTitle);
  }

  /// 死線當日 00:05:「今日[時間]」,冇揀時間就淨係「今日」
  static ({String title, String body}) dayOf(String reminderTitle, {String? timeText}) {
    final title = timeText == null ? '今日' : '今日 $timeText';
    return (title: title, body: reminderTitle);
  }

  /// Dense tier:「仲有 X 分鐘」
  static ({String title, String body}) denseMinutesLeft(String reminderTitle, int minutesLeft) {
    return (title: '仲有 $minutesLeft 分鐘', body: reminderTitle);
  }
}