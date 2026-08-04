import 'package:flutter/material.dart';
import 'apple_year_calendar_view.dart';
import 'apple_month_view.dart';

enum _CalendarMode { month, year }

class CalenderList extends StatefulWidget {
  const CalenderList({super.key});

  @override
  State<CalenderList> createState() => _CalenderListState();
}

class _CalenderListState extends State<CalenderList> {
  // Default landing view is the single-month page — matches Apple Calendar,
  // where you only see the 3x4 year grid after tapping the title to zoom out.
  _CalendarMode _mode = _CalendarMode.month;

  late int _selectedYear = DateTime.now().year;
  late int _selectedMonth = DateTime.now().month;
  DateTime? _selectedDate;

  void _goToPreviousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
  }

  void _goToPreviousYear() => setState(() => _selectedYear--);
  void _goToNextYear() => setState(() => _selectedYear++);

  void _handleDayTapped(DateTime date) {
    setState(() {
      _selectedDate = date;
      // Tapping a dimmed leading/trailing day (e.g. Aug 1 shown while
      // viewing July) should smoothly carry you into that month, like iOS.
      _selectedMonth = date.month;
      _selectedYear = date.year;
    });
    // TODO: push a day-detail / reminders-for-day page here.
    debugPrint('Selected day $date');
  }

  void _handleMonthTapped(int month) {
    setState(() {
      _selectedMonth = month;
      _mode = _CalendarMode.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == _CalendarMode.year) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _goToPreviousYear,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _goToNextYear,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: AppleYearCalendarView(
              year: _selectedYear,
              onMonthTapped: _handleMonthTapped,
              onDayTapped: (date) {
                setState(() {
                  _selectedMonth = date.month;
                  _selectedYear = date.year;
                  _selectedDate = date;
                  _mode = _CalendarMode.month;
                });
              },
            ),
          ),
        ],
      );
    }

    return AppleMonthView(
      year: _selectedYear,
      month: _selectedMonth,
      selectedDate: _selectedDate,
      onDayTapped: _handleDayTapped,
      onPreviousMonth: _goToPreviousMonth,
      onNextMonth: _goToNextMonth,
      onTitleTapped: () => setState(() => _mode = _CalendarMode.year),
    );
  }
}