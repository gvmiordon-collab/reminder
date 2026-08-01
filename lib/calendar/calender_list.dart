import 'package:flutter/material.dart';
import 'apple_year_calendar view.dart';

class CalenderList extends StatefulWidget {
  const CalenderList({super.key});

  @override
  State<CalenderList> createState() => _CalenderListState();
}

class _CalenderListState extends State<CalenderList> {
  // Tracks which year is currently displayed. Starts on the current year.
  late int _selectedYear = DateTime.now().year;

  void _goToPreviousYear() {
    setState(() {
      _selectedYear--;
    });
  }

  void _goToNextYear() {
    setState(() {
      _selectedYear++;
    });
  }

  void _handleMonthTapped(int month) {
    // TODO: push a month-detail page, e.g.:
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => MonthDetailPage(year: _selectedYear, month: month),
    // ));
    debugPrint('Tapped month $month of $_selectedYear');
  }

  void _handleDayTapped(DateTime date) {
    // TODO: push a day-detail / reminders-for-day page here.
    debugPrint('Tapped day $date');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple prev/next year navigation above the grid.
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
            onDayTapped: _handleDayTapped,
            showYearHeader: true,
          ),
        ),
      ],
    );
  }
}