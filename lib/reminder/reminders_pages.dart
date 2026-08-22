import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'reminder_provider.dart';
import 'reminder_structure.dart';
import 'dialog_box.dart';

class RemindersPages extends StatelessWidget {
  const RemindersPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final reminders = provider.reminders;

        return ListView.builder(
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return ReminderStructure(
              key: ValueKey(reminder.id),
              todo: reminder.title,
              date: reminder.displayText,
              onCheck: () => provider.removeReminder(reminder.id!),
              onDelete: () => provider.removeReminder(reminder.id!),
              onEdit: () => showDialog(
                  context: context,
                  builder: (context) => DialogBox(existingReminder: reminder,)
              ),
            );
          },
        );
      },
    );
  }
}