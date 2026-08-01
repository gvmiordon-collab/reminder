import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reminder/reminder/provider.dart';
import 'dialog_box.dart';
import 'reminder_structure.dart';

class RemindersPages extends StatelessWidget {
  const RemindersPages({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>().reminders; // ✅ watch 一定要喺 build 入面

    return ListView.builder(
      itemCount: reminders.length,
      itemBuilder: (context, index) {
        final reminder = reminders[index];
        return ReminderStructure(
          todo: reminder['todo'] ?? '',
          date: reminder['date'] ?? '',
          onDelete: () => context.read<ReminderProvider>().removeReminder(index), // ✅ 事件用 read
          onCheck: () => context.read<ReminderProvider>().finishReminder(index),
        );
      },
    );
  }
}