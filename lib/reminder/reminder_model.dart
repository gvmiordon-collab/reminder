import 'package:intl/intl.dart';

class Reminder {
  final int? id;
  final String title;
  final DateTime dueDate;
  final bool hasTime; // false = 淨係揀咗日期, true = 日期+時間都揀咗
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    this.id,
    required this.title,
    required this.dueDate,
    required this.hasTime,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'hasTime': hasTime ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      title: map['title'] as String,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      hasTime: (map['hasTime'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  /// 過期判斷(已同 Gordon 確認):
  /// - 有時間 -> dueDate 一過就算過期
  /// - 冇時間 -> 過咗嗰日 23:59:59 先算過期
  bool get isOverdue {
    final now = DateTime.now();
    if (hasTime) {
      return now.isAfter(dueDate);
    }
    final endOfDueDay =
    DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);
    return now.isAfter(endOfDueDay);
  }

  /// 畫面顯示格式:Today, 4:30 / Tomorrow, 18:00 / 5 Sep, 3:00 / 5 Sep(冇時間)
  String get displayText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    String dayLabel;
    if (targetDate == today) {
      dayLabel = 'Today';
    } else if (targetDate == tomorrow) {
      dayLabel = 'Tomorrow';
    } else {
      dayLabel = DateFormat('d MMM').format(dueDate);
    }

    if (!hasTime) return dayLabel;
    return '$dayLabel, ${DateFormat('H:mm').format(dueDate)}';
  }
}