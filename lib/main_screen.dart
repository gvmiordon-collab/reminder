import 'package:flutter/material.dart';
import 'package:reminder/reminder/dialog_box.dart';
import 'package:reminder/calendar/calender.dart';
import 'package:reminder/reminder/reminders_pages.dart';
import 'package:reminder/notifications/notification_permission_gate.dart';
import 'package:reminder/notifications/tab_notifier.dart';

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

  @override
  void initState() {
    super.initState();
    requestedTabIndex.addListener(_onTabRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      runNotificationPermissionGate(context);
    });
  }

  void _onTabRequested() {
    if (mounted) setState(() => _currentIndex = requestedTabIndex.value);
  }

  @override
  void dispose() {
    requestedTabIndex.removeListener(_onTabRequested);
    super.dispose();
  }

  void _createNewReminder() {
    showDialog(
      context: context,
      builder: (context) => DialogBox(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent[100],
        title: Text('Reminders', style: TextStyle(color: Colors.white)),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.redAccent,
        shape: CircularNotchedRectangle(),
        notchMargin: 12.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () => setState(() => _currentIndex = 0),
              icon: Icon(Icons.list, color: _currentIndex == 0 ? Colors.yellow : Colors.white),
            ),
            SizedBox(width: 40),
            IconButton(
              onPressed: () => setState(() => _currentIndex = 1),
              icon: Icon(Icons.calendar_month, color: _currentIndex == 1 ? Colors.yellow : Colors.white),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewReminder,
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}