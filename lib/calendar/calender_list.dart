import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      _selectedMonth = date.month;
      _selectedYear = date.year;
    });
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DayRemindersSheet(date: date),
    );
  }

  void _handleMonthTapped(int month) {
    setState(() {
      _selectedMonth = month;
      _mode = _CalendarMode.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Set<DateTime> highlightedDates =
        context.watch<ReminderProvider>().datesWithReminders;

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
              highlightedDates: highlightedDates,
              onMonthTapped: _handleMonthTapped,
              onDayTapped: (date) {
                // 撳年視圖入面某一日 = 跳返月視圖睇該月,暫時未喺呢度彈 bottom sheet
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
      highlightedDates: highlightedDates,
      onDayTapped: _handleDayTapped,
      onPreviousMonth: _goToPreviousMonth,
      onNextMonth: _goToNextMonth,
      onTitleTapped: () => setState(() => _mode = _CalendarMode.year),
    );
  }
}