import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dialog_box.dart';
import 'reminder_structure.dart';

class RemindersPages extends StatelessWidget {
  const RemindersPages({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ReminderStructure(todo: 'TODO_1', date: 'Today, 4:30'),
        ReminderStructure(todo: 'TODO_2', date: 'Tomorrow, 18:00'),
        ReminderStructure(todo: 'TODO_3', date: '5 Sep, 3:00'),
      ],
    );
  }
}