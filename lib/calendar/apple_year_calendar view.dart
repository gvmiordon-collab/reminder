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
  });

  /// The year to render (e.g. 2026).
  final int year;

  /// Called when the header of a month (its abbreviated name) is tapped.
  final ValueChanged<int>? onMonthTapped;

  /// Called when an individual day cell is tapped.
  final ValueChanged<DateTime>? onDayTapped;

  /// Color used for the "today" indicator circle. Defaults to iOS systemRed.
  final Color todayColor;

  /// Background color of the whole view. Defaults to white to match the
  /// minimalist iOS Calendar aesthetic.
  final Color backgroundColor;

  /// Whether to render the large "2026"-style year header above the grid.
  final bool showYearHeader;

  /// Aspect ratio (width / height) of each month box in the 3x4 grid.
  /// Tune this if you change fonts/spacing and need to avoid overflow.
  final double childAspectRatio;

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
                style: const TextStyle(
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
              mainAxisSpacing: 22,
              crossAxisSpacing: 10,
              childAspectRatio: childAspectRatio,
              children: List.generate(12, (index) {
                final int month = index + 1;
                return _MonthBox(
                  year: year,
                  month: month,
                  today: today,
                  monthLabel: _monthAbbreviations[index],
                  todayColor: todayColor,
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

/// A single mini-month box: month abbreviation header + micro day grid.
class _MonthBox extends StatelessWidget {
  const _MonthBox({
    required this.year,
    required this.month,
    required this.today,
    required this.monthLabel,
    required this.todayColor,
    this.onMonthTapped,
    this.onDayTapped,
  });

  final int year;
  final int month;
  final DateTime today;
  final String monthLabel;
  final Color todayColor;
  final ValueChanged<int>? onMonthTapped;
  final ValueChanged<DateTime>? onDayTapped;

  bool _isToday(DateTime date) {
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  /// Builds the rows of the micro day-grid (7 columns: Sun–Sat), using pure
  /// `DateTime` math — no external date libraries.
  List<Widget> _buildDayRows() {
    final DateTime firstOfMonth = DateTime(year, month, 1);
    // Day 0 of "next month" is the last day of the current month.
    final int daysInMonth = DateTime(year, month + 1, 0).day;

    // Dart's DateTime.weekday is Monday=1 ... Sunday=7.
    // Convert to a Sunday-first index: Sunday=0 ... Saturday=6.
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
                todayColor: todayColor,
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
              style: const TextStyle(
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
/// indicator with white bold text when applicable.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.todayColor,
    this.onTap,
  });

  final int day;
  final bool isToday;
  final Color todayColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: Center(
          child: isToday
              ? Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: todayColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          )
              : Text(
            '$day',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}