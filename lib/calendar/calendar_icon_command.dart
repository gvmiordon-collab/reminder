import 'package:flutter/foundation.dart';

/// 撳 MainScreen 個 calendar icon 之後,想 Calendar 嗰邊做咩:
/// - resetToMonth:本身唔喺 Calendar tab,跳過去嗰陣一律顯示 month view
/// - toggleMonthYear:已經企喺 Calendar tab,喺 month/year 之間切換
enum CalendarIconCommand { resetToMonth, toggleMonthYear }

/// 包多個 nonce 先送出去:就算連續兩次係同一個 command(例如連撳兩下
/// toggle),ValueNotifier 淨係睇 value 相唔相等嚟決定通唔通知 listener,
/// 兩個 enum value 相同會畀佢當「冇變化」唔觸發。加個逐次遞增嘅 nonce
/// 保證每次一定觸發到。
class CalendarIconCommandNotifier
    extends ValueNotifier<({CalendarIconCommand command, int nonce})?> {
  CalendarIconCommandNotifier() : super(null);

  int _nonce = 0;

  void send(CalendarIconCommand command) {
    _nonce++;
    value = (command: command, nonce: _nonce);
  }
}

final calendarIconCommand = CalendarIconCommandNotifier();