import 'package:flutter/material.dart';

/// A pixel-perfect recreation of Apple Calendar's "Year View" — a compact
/// 3x4 grid of 12 mini-month calendars — built with pure Flutter and no
/// third-party calendar packages. All day-grid math is derived from
/// standard `DateTime` utilities.
///
/// Usage:
/// ```dart
/// AppleYearCalendarView(
///   year: 2026,
///   reminderDates: provider.datesWithReminders,
///   onMonthTapped: (month) => debugPrint('Tapped month $month'),
///   onDayTapped: (date) => debugPrint('Tapped day $date'),
/// )
/// ```
class AppleYearCalendarView extends StatelessWidget {
  const AppleYearCalendarView({
    super.key,
    required this.year,
    this.onMonthTapped,
    this.onDayTapped,
    this.todayColor = const Color(0xFFFF3B30), // iOS systemRed
    this.backgroundColor = Colors.white,
    this.showYearHeader = true,
    this.childAspectRatio = 0.82,
    this.yearHeaderStyle,
    this.monthLabelStyle,
    this.dayNumberStyle,
    this.todayNumberStyle,
    this.todayCircleSize = 16,
    this.mainAxisSpacing = 22,
    this.crossAxisSpacing = 10,
    this.reminderDates = const <DateTime>{},
    this.reminderDotColor = const Color(0xFFAF52DE), // iOS systemPurple
  });

  final int year;
  final ValueChanged<int>? onMonthTapped;
  final ValueChanged<DateTime>? onDayTapped;
  final Color todayColor;
  final Color backgroundColor;
  final bool showYearHeader;
  final double childAspectRatio;
  final TextStyle? yearHeaderStyle;
  final TextStyle? monthLabelStyle;
  final TextStyle? dayNumberStyle;
  final TextStyle? todayNumberStyle;
  final double todayCircleSize;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  /// Dates (day-only) that should show a tiny purple dot beneath the day
  /// number, indicating a reminder is due that day.
  final Set<DateTime> reminderDates;

  /// Color of the reminder-indicator dot. Defaults to iOS systemPurple.
  final Color reminderDotColor;

  static const List<String> _monthAbbreviations = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    return Container(
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showYearHeader)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '$year',
                style: yearHeaderStyle ??
                    const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
              ),
            ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
              children: List.generate(12, (index) {
                final int month = index + 1;
                return _MonthBox(
                  year: year,
                  month: month,
                  today: today,
                  monthLabel: _monthAbbreviations[index],
                  todayColor: todayColor,
                  reminderDates: reminderDates,
                  reminderDotColor: reminderDotColor,
                  monthLabelStyle: monthLabelStyle,
                  dayNumberStyle: dayNumberStyle,
                  todayNumberStyle: todayNumberStyle,
                  todayCircleSize: todayCircleSize,
                  onMonthTapped: onMonthTapped,
                  onDayTapped: onDayTapped,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBox extends StatelessWidget {
  const _MonthBox({
    required this.year,
    required this.month,
    required this.today,
    required this.monthLabel,
    required this.todayColor,
    required this.reminderDates,
    required this.reminderDotColor,
    this.monthLabelStyle,
    this.dayNumberStyle,
    this.todayNumberStyle,
    this.todayCircleSize = 16,
    this.onMonthTapped,
    this.onDayTapped,
  });

  final int year;
  final int month;
  final DateTime today;
  final String monthLabel;
  final Color todayColor;
  final Set<DateTime> reminderDates;
  final Color reminderDotColor;
  final TextStyle? monthLabelStyle;
  final TextStyle? dayNumberStyle;
  final TextStyle? todayNumberStyle;
  final double todayCircleSize;
  final ValueChanged<int>? onMonthTapped;
  final ValueChanged<DateTime>? onDayTapped;

  bool _isToday(DateTime date) {
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  List<Widget> _buildDayRows() {
    final DateTime firstOfMonth = DateTime(year, month, 1);
    final int daysInMonth = DateTime(year, month + 1, 0).day;

    final int startOffset = firstOfMonth.weekday % 7;
    final int totalCells = startOffset + daysInMonth;
    final int rowCount = (totalCells / 7).ceil();

    int dayCounter = 1;
    final List<Widget> rows = <Widget>[];

    for (int r = 0; r < rowCount; r++) {
      final List<Widget> rowChildren = <Widget>[];
      for (int c = 0; c < 7; c++) {
        final int cellIndex = r * 7 + c;
        if (cellIndex < startOffset || dayCounter > daysInMonth) {
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        } else {
          final DateTime date = DateTime(year, month, dayCounter);
          final int currentDay = dayCounter;
          rowChildren.add(
            Expanded(
              child: _DayCell(
                day: currentDay,
                isToday: _isToday(date),
                hasReminder: reminderDates.contains(date),
                todayColor: todayColor,
                dotColor: reminderDotColor,
                dayNumberStyle: dayNumberStyle,
                todayNumberStyle: todayNumberStyle,
                todayCircleSize: todayCircleSize,
                onTap: onDayTapped == null ? null : () => onDayTapped!(date),
              ),
            ),
          );
          dayCounter++;
        }
      }
      rows.add(Row(children: rowChildren));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onMonthTapped == null ? null : () => onMonthTapped!(month),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              monthLabel,
              textAlign: TextAlign.center,
              style: monthLabelStyle ??
                  const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.0,
                  ),
            ),
          ),
        ),
        ..._buildDayRows(),
      ],
    );
  }
}

/// A single day number cell. Renders the solid red circular "today"
/// indicator with white bold text when applicable, plus a tiny purple dot
/// beneath the number when [hasReminder] is true.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasReminder,
    required this.todayColor,
    required this.dotColor,
    this.dayNumberStyle,
    this.todayNumberStyle,
    this.todayCircleSize = 16,
    this.onTap,
  });

  final int day;
  final bool isToday;
  final bool hasReminder;
  final Color todayColor;
  final Color dotColor;
  final TextStyle? dayNumberStyle;
  final TextStyle? todayNumberStyle;
  final double todayCircleSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget number = isToday
        ? Container(
      width: todayCircleSize,
      height: todayCircleSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: todayColor, shape: BoxShape.circle),
      child: Text(
        '$day',
        style: todayNumberStyle ??
            const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.0,
            ),
      ),
    )
        : Text(
      '$day',
      style: dayNumberStyle ??
          const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.0,
          ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          alignment: Alignment.center,
          children: [
            number,
            if (hasReminder)
              Align(
                alignment: const Alignment(0, 0.85), // 貼近底部,唔佔額外高度
                child: Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}