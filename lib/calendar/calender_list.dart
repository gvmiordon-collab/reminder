// lib/calendar/calender_list.dart
import 'calendar_icon_command.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/reminder/reminder_model.dart';
import 'package:reminder/reminder/reminder_provider.dart';
import 'apple_year_calendar_view.dart';
import 'apple_month_view.dart';
import 'day_reminders_sheet.dart';

enum _CalendarMode { month, year }

class CalenderList extends StatefulWidget {
  const CalenderList({super.key});

  @override
  State<CalenderList> createState() => _CalenderListState();
}

class _CalenderListState extends State<CalenderList> {
  _CalendarMode _mode = _CalendarMode.month;

  // === Swipe 分頁機制 ===
  // Month/Year 各自一個 PageController,page index 同實際月/年嘅
  // 對應關係:page = _pageMiddle + (距離 anchor 幾多個月/年)。
  // anchor 淨係喺 initState 攞一次(建立嗰陣嘅「而家」),之後全程唔變;
  // _pageMiddle 揀一個好大嘅起始頁,等使用者可以隨便向前向後掃(月曆
  // 大概 500 年、年曆 6000 年),一個 reminder app 用嚟講已經用唔晒。
  static const int _pageMiddle = 6000;

  late final DateTime _monthAnchor;
  late final PageController _monthPageController;
  int _monthPageIndex = _pageMiddle;

  late final int _yearAnchor;
  late final PageController _yearPageController;
  int _yearPageIndex = _pageMiddle;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    calendarIconCommand.addListener(_handleCalendarIconCommand); // 新增
    final now = DateTime.now();
    _monthAnchor = DateTime(now.year, now.month);
    _monthPageController = PageController(initialPage: _pageMiddle);
    _yearAnchor = now.year;
    _yearPageController = PageController(initialPage: _pageMiddle);
  }

  @override
  void dispose() {
    calendarIconCommand.removeListener(_handleCalendarIconCommand); // 新增
    _monthPageController.dispose();
    _yearPageController.dispose();
    super.dispose();
  }

  DateTime _dateForMonthPage(int page) {
    final offset = page - _pageMiddle;
    return DateTime(_monthAnchor.year, _monthAnchor.month + offset);
  }

  int _pageForMonth(DateTime date) {
    return _pageMiddle +
        (date.year - _monthAnchor.year) * 12 +
        (date.month - _monthAnchor.month);
  }

  int _yearForPage(int page) => _yearAnchor + (page - _pageMiddle);

  int _pageForYear(int year) => _pageMiddle + (year - _yearAnchor);

  void _goToPreviousMonth() {
    _monthPageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToNextMonth() {
    _monthPageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToPreviousYear() {
    _yearPageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToNextYear() {
    _yearPageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // 撳月曆入面淡色嘅上/下個月日子:淨係差 1 個月,當佢係「撳咗
  // chevron」處理,有動畫,同手指滑嗰種順滑感覺一致。
  void _handleDayTapped(DateTime date) {
    final currentMonth = _dateForMonthPage(_monthPageIndex);
    final tappedMonth = DateTime(date.year, date.month);
    if (tappedMonth.isBefore(currentMonth)) {
      _goToPreviousMonth();
    } else if (tappedMonth.isAfter(currentMonth)) {
      _goToNextMonth();
    }
    setState(() => _selectedDate = date);
    _showDayRemindersSheet(date);
  }

  // 年曆撳月份標籤 / 撳日子跳去月曆:距離可以好遠(例如成十年),
  // 用 jumpToPage 即刻跳,唔做動畫。
  void _handleMonthTapped(int month) {
    final targetYear = _yearForPage(_yearPageIndex);
    final targetPage = _pageForMonth(DateTime(targetYear, month));
    _monthPageController.jumpToPage(targetPage);
    setState(() {
      _monthPageIndex = targetPage;
      _mode = _CalendarMode.month;
    });
  }

  void _handleYearViewDayTapped(DateTime date) {
    final targetPage = _pageForMonth(date);
    _monthPageController.jumpToPage(targetPage);
    setState(() {
      _monthPageIndex = targetPage;
      _selectedDate = date;
      _mode = _CalendarMode.month;
    });
  }

  void _handleTitleTapped() {
    final currentYear = _dateForMonthPage(_monthPageIndex).year;
    final targetPage = _pageForYear(currentYear);
    _yearPageController.jumpToPage(targetPage);
    setState(() {
      _yearPageIndex = targetPage;
      _mode = _CalendarMode.year;
    });
  }


  // 處理 MainScreen 個 calendar icon 掣傳落嚟嘅指令
// (見 calendar_icon_command.dart):reset 或者 toggle month/year。
  void _handleCalendarIconCommand() {
    final cmd = calendarIconCommand.value;
    if (cmd == null) return;

    switch (cmd.command) {
      case CalendarIconCommand.resetToMonth:
        setState(() => _mode = _CalendarMode.month);
        break;
      case CalendarIconCommand.toggleMonthYear:
        if (_mode == _CalendarMode.month) {
          // 同 _handleTitleTapped 一樣邏輯:轉去 year view 之前,
          // 令 year page 同而家顯示緊嗰個月份嘅年份對得上。
          final currentYear = _dateForMonthPage(_monthPageIndex).year;
          final targetPage = _pageForYear(currentYear);
          _yearPageController.jumpToPage(targetPage);
          setState(() {
            _yearPageIndex = targetPage;
            _mode = _CalendarMode.year;
          });
        } else {
          setState(() => _mode = _CalendarMode.month);
        }
        break;
    }
  }


  void _showDayRemindersSheet(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DayRemindersSheet(date: date),
    );
  }

  Set<DateTime> _reminderDatesFrom(List<Reminder> reminders) {
    return reminders
        .map((r) => DateTime(r.dueDate.year, r.dueDate.month, r.dueDate.day))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    // 淨係讀 reminders 嚟計邊日要 highlight,冇任何 DB/business logic 喺呢層。
    final reminders = context.watch<ReminderProvider>().reminders;
    final reminderDates = _reminderDatesFrom(reminders);

    return IndexedStack(
      index: _mode == _CalendarMode.month ? 0 : 1,
      children: [
        PageView.builder(
          controller: _monthPageController,
          onPageChanged: (index) => setState(() => _monthPageIndex = index),
          itemBuilder: (context, index) {
            final monthDate = _dateForMonthPage(index);
            return AppleMonthView(
              year: monthDate.year,
              month: monthDate.month,
              selectedDate: _selectedDate,
              reminderDates: reminderDates,
              onDayTapped: _handleDayTapped,
              onPreviousMonth: _goToPreviousMonth,
              onNextMonth: _goToNextMonth,
              onTitleTapped: _handleTitleTapped,
            );
          },
        ),
        PageView.builder(
          controller: _yearPageController,
          onPageChanged: (index) => setState(() => _yearPageIndex = index),
          itemBuilder: (context, index) {
            final year = _yearForPage(index);
            return AppleYearCalendarView(
              year: year,
              reminderDates: reminderDates,
              onMonthTapped: _handleMonthTapped,
              onPreviousYear: _goToPreviousYear,
              onNextYear: _goToNextYear,
              onDayTapped: _handleYearViewDayTapped,
            );
          },
        ),
      ],
    );
  }
}