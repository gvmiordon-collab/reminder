import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 新增：引入 Cupertino 元件庫
import 'package:intl/intl.dart';
import 'package:reminder/reminder/my_button.dart';

class DialogBox extends StatefulWidget {
  DialogBox({super.key});

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> {
  final _todocontrollor = TextEditingController();
  DateTime? _selectedDateTime;

  @override
  void dispose() {
    _todocontrollor.dispose();
    super.dispose();
  }

  String get formattedText {
    if (_selectedDateTime == null) {
      return "dealing (請選擇截止時間)";
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(
      _selectedDateTime!.year,
      _selectedDateTime!.month,
      _selectedDateTime!.day,
    );

    // 格式化為 12 小時制顯示，例如 "3:00 PM" 或 "4:30 AM"
    // 如果你想維持 24 小時制顯示可以改回 'H:mm'
    final timeStr = DateFormat('h:mm a').format(_selectedDateTime!);

    if (targetDate == today) {
      return "Today, $timeStr";
    } else if (targetDate == tomorrow) {
      return "Tomorrow, $timeStr";
    } else {
      final dateStr = DateFormat('d MMM').format(_selectedDateTime!);
      return "$dateStr, $timeStr";
    }
  }

  Future<void> _pickDateTime(BuildContext context) async {
    // 1. 揀日期 (保持不變)
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    // 2. 揀時間 (改用 iOS 風格滾輪)
    DateTime tempTime = _selectedDateTime ?? DateTime.now();

    // 使用 showCupertinoModalPopup 底部彈出滾輪
    final bool? confirmTime = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (BuildContext builderContext) {
        return Container(
          height: 260,
          color: Colors.white, // 背景顏色
          child: Column(
            children: [
              // 頂部導航列 (取消 / 完成)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('取消'),
                    onPressed: () => Navigator.of(builderContext).pop(false),
                  ),
                  CupertinoButton(
                    child: const Text('完成', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => Navigator.of(builderContext).pop(true),
                  ),
                ],
              ),
              const Divider(height: 1, thickness: 1),
              // iOS 滾輪主體
              Expanded(
                child: SafeArea(
                  top: false,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false, // 確保是 12小時制 (出現 1-12, 00-59, AM/PM)
                    initialDateTime: tempTime,
                    onDateTimeChanged: (DateTime newTime) {
                      tempTime = newTime; // 滾動時即時更新臨時變數
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    // 如果冇撳「完成」就退出
    if (confirmTime != true) return;

    // 3. 將日曆嘅「日期」同滾輪嘅「時間」結合
    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        tempTime.hour,
        tempTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _todocontrollor,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'what you want to do?'
              ),
            ),
            const SizedBox(height: 12.0),

            // 日期時間選擇按鈕
            InkWell(
              onTap: () => _pickDateTime(context),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black54),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.transparent,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _selectedDateTime == null ? Colors.black54 : Colors.black87,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formattedText,
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDateTime == null ? Colors.black54 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MyButton(
                    name: 'confirm',
                    onPressed: () {},
                    color: Colors.tealAccent
                ),
                const SizedBox(width: 8.0),
                MyButton(
                    name: 'cancel',
                    onPressed: () => Navigator.pop(context),
                    color: Colors.orangeAccent
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}