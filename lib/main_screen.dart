import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/reminder/dialog_box.dart';
import 'package:reminder/calendar/calender.dart';
import 'package:reminder/reminder/reminders_pages.dart';
import 'package:reminder/reminder/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    RemindersPages(),
    Calender(),
  ];

  Future<void> _createNewReminder() async {
    final result = await showDialog(
      context: context,
      builder: (context) => DialogBox(),
    );
    if (result == null) return; // 使用者按 cancel
    context.read<ReminderProvider>().addReminder(result['todo']!, result['date']!);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Reminders'),
      ),
      //
      body: _pages[_currentIndex],
      //
      bottomNavigationBar: BottomAppBar(
        color: Colors.redAccent,
        shape: CircularNotchedRectangle(),
        notchMargin: 12.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: () {
              setState(() {
                _currentIndex = 0;
              });
            },
              icon: Icon(
                  Icons.list,
                color: _currentIndex == 0 ? Colors.yellow : Colors.white,
              ),
            ),
            SizedBox(width: 40,),
            IconButton(onPressed: () {
              setState(() {
                _currentIndex = 1;
              });
            },
              icon: Icon(
                  Icons.calendar_month,
                color: _currentIndex == 1 ? Colors.yellow : Colors.white,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:  _createNewReminder,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
