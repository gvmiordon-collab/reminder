import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 記得引入 intl package 處理日期格式
import 'package:reminder/reminder/my_button.dart';

class DialogBox extends StatefulWidget {
  DialogBox({super.key});

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> {
  final _todocontrollor = TextEditingController();

  // 1. 用 DateTime 變數取代原本的 _datecontroller
  DateTime? _selectedDateTime;

  @override
  void dispose() {
    _todocontrollor.dispose();
    // 移除了 _datecontroller.dispose()
    super.dispose();
  }

  // 2. 處理文字顯示格式的邏輯
  String get formattedText {
    if (_selectedDateTime == null) {
      return "dealing (請選擇截止時間)"; // 預設的提示文字
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(
      _selectedDateTime!.year,
      _selectedDateTime!.month,
      _selectedDateTime!.day,
    );

    final timeStr = DateFormat('H:mm').format(_selectedDateTime!);

    if (targetDate == today) {
      return "Today, $timeStr";
    } else if (targetDate == tomorrow) {
      return "Tomorrow, $timeStr";
    } else {
      final dateStr = DateFormat('d MMM').format(_selectedDateTime!);
      return "$dateStr, $timeStr";
    }
  }

  // 3. 彈出日曆與時間選擇器的邏輯
  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDateTime!)
          : TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
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
            const SizedBox(height: 12.0), // 稍微拉開一點距離

            // ==========================================
            // 4. 這裡取代了原本的 TextField
            // ==========================================
            InkWell(
              onTap: () => _pickDateTime(context),
              borderRadius: BorderRadius.circular(4), // 配合 OutlineInputBorder 的圓角
              child: Container(
                width: double.infinity, // 讓按鈕寬度跟上面的 TextField 一樣
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // 調整高度使其與 TextField 相若
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black54), // 模仿 TextField 的邊框
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
            // ==========================================

            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MyButton(
                    name: 'confirm',
                    onPressed: () {
                      // 當按下 confirm 時，你可以直接使用 _selectedDateTime
                      // print('Task: ${_todocontrollor.text}, Deadline: $_selectedDateTime');
                    },
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