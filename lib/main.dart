import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/main_screen.dart';
import 'package:reminder/reminder/reminder_provider.dart';

void main() {
  runApp(const Reminder());
}

class Reminder extends StatelessWidget {
  const Reminder({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReminderProvider()..load(),
      child: MaterialApp(
        home: const MainScreen(),
      ),
    );
  }
}