import 'package:flutter/material.dart';

/// A single full-size month page, styled like Apple Calendar's default
/// "month view" — much bigger day numbers than the 3x4 year grid, a
/// weekday header row (Sun–Sat), and prev/next month navigation.
///
/// Leading/trailing days from the adjacent months are shown dimmed, exactly
/// like iOS, so the grid always fills a clean rectangle of full weeks.
///
/// Usage:
/// ```dart
/// AppleMonthView(
///   year: 2026,
///   month: 8,
///   selectedDate: _selectedDate,
///   highlightedDates: provider.datesWithReminders, // 有 reminder 嘅日子
///   onDayTapped: (date) => setState(() => _selectedDate = date),
///   onPreviousMonth: _goToPreviousMonth,
///   onNextMonth: _goToNextMonth,
///   onTitleTapped: () => setState(() => _mode = _CalendarMode.year),
/// )
/// ```
class AppleMonthView extends StatelessWidget {
  const AppleMonthView({
    super.key,
    required this.year,
    required this.month,
    this.onDayTapped,
    this.onPreviousMonth,
    this.onNextMonth,
    this.onTitleTapped,
    this.selectedDate,
    this.todayColor = const Color(0xFFFF3B30), // iOS systemRed
    this.selectedColor = const Color(0xFFE5E5EA), // iOS systemGray5
    this.backgroundColor = Colors.white,
    this.titleStyle,
    this.weekdayLabelStyle,
    this.dayNumberStyle,
    this.todayNumberStyle,
    this.selectedNumberStyle,
    this.otherMonthNumberStyle,
    this.showLeadingTrailingDays = true,
    this.highlightedDates = const <DateTime>{},
    this.highlightColor = const Color(0xFFAF52DE), // iOS systemPurple
  });

  /// The year of the month being displayed (e.g. 2026).
  final int year;

  /// The month being displayed, 1–12.
  final int month;

  /// Called whenever a day cell is tapped — including dimmed leading/
  /// trailing days that belong to the adjacent month.
  final ValueChanged<DateTime>? onDayTapped;

  /// Called when the left chevron is tapped (go to previous month).
  final VoidCallback? onPreviousMonth;

  /// Called when the right chevron is tapped (go to next month).
  final VoidCallback? onNextMonth;

  /// Called when the "Month Year" title is tapped — hook this up to switch
  /// to a year/grid view, just like tapping "‹ 2026" in Apple Calendar.
  final VoidCallback? onTitleTapped;

  /// The currently selected day, if any. Shown with a light grey circle
  /// (distinct from the solid red "today" circle).
  final DateTime? selectedDate;

  final Color todayColor;
  final Color selectedColor;
  final Color backgroundColor;

  /// Style for the "August 2026" header (default: 20, bold, black).
  final TextStyle? titleStyle;

  /// Style for the S M T W T F S weekday row (default: 12, grey).
  final TextStyle? weekdayLabelStyle;

  /// Style for a normal in-month day number (default: 17, black).
  final TextStyle? dayNumberStyle;

  /// Style for the number inside the red "today" circle (default: 17, white).
  final TextStyle? todayNumberStyle;

  /// Style for the number inside the grey "selected" circle (default: 17, black).
  final TextStyle? selectedNumberStyle;

  /// Style for dimmed leading/trailing days from adjacent months.
  final TextStyle? otherMonthNumberStyle;

  /// Whether to show the dimmed days from the previous/next month that fill
  /// out the first/last week. If false, those cells are left blank.
  final bool showLeadingTrailingDays;

  /// Dates (day-only — time component ignored) that should show a small
  /// dot beneath the day number, indicating a reminder is due that day.
  final Set<DateTime> highlightedDates;

  /// Color of the reminder-indicator dot. Defaults to iOS systemPurple.
  final Color highlightColor;

  static const List<String> _monthNames = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> _weekdayLabels = <String>[
    'S', 'M', 'T', 'W', 'T', 'F', 'S',
  ];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime firstOfMonth = DateTime(year, month, 1);
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int daysInPrevMonth = DateTime(year, month, 0).day;

    final int startOffset = firstOfMonth.weekday % 7;
    final int totalCells = startOffset + daysInMonth;
    final int rowCount = (totalCells / 7).ceil();

    final List<_DayInfo> cells = List.generate(rowCount * 7, (i) {
      final int dayOffset = i - startOffset;
      if (dayOffset < 0) {
        final int day = daysInPrevMonth + dayOffset + 1;
        final int prevMonth = month == 1 ? 12 : month - 1;
        final int prevYear = month == 1 ? year - 1 : year;
        return _DayInfo(DateTime(prevYear, prevMonth, day), false);
      } else if (dayOffset >= daysInMonth) {
        final int day = dayOffset - daysInMonth + 1;
        final int nextMonth = month == 12 ? 1 : month + 1;
        final int nextYear = month == 12 ? year + 1 : year;
        return _DayInfo(DateTime(nextYear, nextMonth, day), false);
      } else {
        return _DayInfo(DateTime(year, month, dayOffset + 1), true);
      }
    });

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPreviousMonth,
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTitleTapped,
                    child: Text(
                      '${_monthNames[month - 1]} $year',
                      textAlign: TextAlign.center,
                      style: titleStyle ??
                          const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNextMonth,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: List.generate(7, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _weekdayLabels[i],
                      style: weekdayLabelStyle ??
                          TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: List.generate(rowCount, (r) {
                  return Expanded(
                    child: Row(
                      children: List.generate(7, (c) {
                        final _DayInfo info = cells[r * 7 + c];
                        if (!info.inCurrentMonth && !showLeadingTrailingDays) {
                          return const Expanded(child: SizedBox.shrink());
                        }
                        final bool isToday = _isSameDay(info.date, today);
                        final bool isSelected = selectedDate != null &&
                            _isSameDay(info.date, selectedDate!);
                        final bool hasReminder = highlightedDates.contains(
                          DateTime(info.date.year, info.date.month, info.date.day),
                        );
                        return Expanded(
                          child: _MonthDayCell(
                            date: info.date,
                            isToday: isToday,
                            isSelected: isSelected,
                            inCurrentMonth: info.inCurrentMonth,
                            hasReminder: hasReminder,
                            todayColor: todayColor,
                            selectedColor: selectedColor,
                            dotColor: highlightColor,
                            dayNumberStyle: dayNumberStyle,
                            todayNumberStyle: todayNumberStyle,
                            selectedNumberStyle: selectedNumberStyle,
                            otherMonthNumberStyle: otherMonthNumberStyle,
                            onTap: onDayTapped == null
                                ? null
                                : () => onDayTapped!(info.date),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayInfo {
  const _DayInfo(this.date, this.inCurrentMonth);
  final DateTime date;
  final bool inCurrentMonth;
}

/// A single tappable day cell inside the month grid. Solid red circle for
/// "today", light grey circle for a tapped/selected day, dimmed grey text
/// for adjacent-month days, and a small purple dot beneath the number when
/// [hasReminder] is true.
class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.inCurrentMonth,
    required this.hasReminder,
    required this.todayColor,
    required this.selectedColor,
    required this.dotColor,
    this.dayNumberStyle,
    this.todayNumberStyle,
    this.selectedNumberStyle,
    this.otherMonthNumberStyle,
    this.onTap,
  });

  final DateTime date;
  final bool isToday;
  final bool isSelected;
  final bool inCurrentMonth;
  final bool hasReminder;
  final Color todayColor;
  final Color selectedColor;
  final Color dotColor;
  final TextStyle? dayNumberStyle;
  final TextStyle? todayNumberStyle;
  final TextStyle? selectedNumberStyle;
  final TextStyle? otherMonthNumberStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget number;

    if (isToday) {
      number = Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: todayColor, shape: BoxShape.circle),
        child: Text(
          '${date.day}',
          style: todayNumberStyle ??
              const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
        ),
      );
    } else if (isSelected) {
      number = Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selectedColor, shape: BoxShape.circle),
        child: Text(
          '${date.day}',
          style: selectedNumberStyle ??
              const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
        ),
      );
    } else {
      number = Text(
        '${date.day}',
        style: (inCurrentMonth ? dayNumberStyle : otherMonthNumberStyle) ??
            TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w400,
              color: inCurrentMonth ? Colors.black : Colors.grey.shade400,
            ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            number,
            const SizedBox(height: 3),
            // 固定留位,唔理有冇 reminder 都佔緊呢行高度,咁行與行之間先對得齊
            SizedBox(
              width: 5,
              height: 5,
              child: hasReminder
                  ? DecoratedBox(
                decoration:
                BoxDecoration(color: dotColor, shape: BoxShape.circle),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}