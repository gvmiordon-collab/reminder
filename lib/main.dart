import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/main_screen.dart';
import 'package:reminder/reminder/reminder_provider.dart';
import 'package:reminder/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // runApp 之前用 plugin 一定要先行呢句

  // 通知初始化包埋 try-catch:就算初始化失敗(例如全新安裝嘅
  // edge case),都唔應該累到成個 App 卡喺白畫面度開唔到。有事淨係
  // log 低,App 照樣入到主畫面,notification 功能可能今次未必即刻
  // work,但至少唔會完全卡死。
  try {
    await NotificationService.instance.init();
  } catch (e, st) {
    debugPrint('NotificationService.init() 失敗: $e\n$st');
  }

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