import 'package:flutter/material.dart';

/// 公眾假期卡:喺「撳日子彈出嘅 sheet」度,同 reminder 卡
/// ([ReminderStructure])分開顯示。
///
/// 外觀跟 reminder 卡一致(字體大細 26 bold、間距、圓角),
/// 分別係:底色用淡紅色、冇日期/時間行、冇左右滑掣
/// (假期唔可以完成或者刪除)。
class HolidayCard extends StatelessWidget {
  const HolidayCard({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red[100], // 淡紅色,想微調改呢行
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}