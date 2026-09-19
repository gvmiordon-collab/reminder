import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reminder/reminder/reminder_provider.dart';
import 'package:reminder/reminder/reminder_structure.dart';
import 'package:reminder/reminder/dialog_box.dart';
import 'package:reminder/calendar/hk_holidays.dart';
import 'package:reminder/calendar/holiday_card.dart';

/// 撳日子彈出嘅 bottom sheet:顯示嗰日嘅 reminder list,
/// 可以直接 slide check/delete —— 同主 Reminders tab 一樣嘅操作,
/// 兩邊都係 call `ReminderProvider.removeReminder`(完成=刪除),
/// 保證行為一致。
///
/// 如果嗰日係有名嘅公眾假期,list 最頂會多一張淡紅色假期卡
/// ([HolidayCard]),純星期日就唔會有。
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

        final holidayName = hkHolidayNameOf(date);
        final holidayCount = holidayName != null ? 1 : 0;
        final itemCount = holidayCount + dayReminders.length;

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
                if (itemCount == 0)
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
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // 有假期嘅話,第 0 格固定係假期卡
                        if (holidayName != null && index == 0) {
                          return HolidayCard(name: holidayName);
                        }
                        final reminder = dayReminders[index - holidayCount];
                        return ReminderStructure(
                          key: ValueKey(reminder.id),
                          todo: reminder.title,
                          date: reminder.displayText,
                          onCheck: () =>
                              provider.removeReminder(reminder.id!),
                          onDelete: () =>
                              provider.removeReminder(reminder.id!),
                          onEdit: () => showDialog(
                            context: context,
                            builder: (context) =>
                                DialogBox(existingReminder: reminder),
                          ),
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