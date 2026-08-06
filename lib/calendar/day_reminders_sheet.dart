import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reminder/reminder/reminder_provider.dart';
import 'package:reminder/reminder/reminder_structure.dart';

/// 撳日子彈出嘅 bottom sheet:顯示嗰日嘅 reminder list,
/// 可以直接 slide check/delete —— 同主 Reminders tab 一樣嘅操作,
/// 兩邊都係 call `ReminderProvider.removeReminder`(完成=刪除),
/// 保證行為一致。
class DayRemindersSheet extends StatelessWidget {
  const DayRemindersSheet({super.key, required this.date});

  final DateTime date;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReminderProvider>(
      builder: (context, provider, _) {
        final dayReminders = provider.reminders
            .where((r) => _isSameDay(r.dueDate, date))
            .toList();

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat('d MMMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (dayReminders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      '呢日冇 reminder',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: dayReminders.length,
                      itemBuilder: (context, index) {
                        final reminder = dayReminders[index];
                        return ReminderStructure(
                          key: ValueKey(reminder.id),
                          todo: reminder.title,
                          date: reminder.displayText,
                          onCheck: () =>
                              provider.removeReminder(reminder.id!),
                          onDelete: () =>
                              provider.removeReminder(reminder.id!),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}