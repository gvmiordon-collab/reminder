import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/main_screen.dart';
import 'package:reminder/reminder/reminder_provider.dart';
import 'package:reminder/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // runApp 之前用 plugin 一定要先行呢句
  await NotificationService.instance.init();
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