import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 記得引入 intl package 處理日期格式
import 'package:reminder/reminder/my_button.dart';
import 'package:flutter/cupertino.dart';

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
    // === 第一部分：保留原本的日曆選擇器 (完全無改動) ===
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    // === 第二部分：改為置中的 iOS 風格滾輪時間選擇器 ===
    final TimeOfDay? pickedTime = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        // 記錄滾輪當前的時間，預設為剛剛選中或現在的時間
        DateTime tempTime = _selectedDateTime ?? DateTime.now();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            height: 300, // 控制對話框高度
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '選擇時間',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // iOS 風格滾輪
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false, // false 代表會顯示 1-12 以及 AM/PM
                    initialDateTime: tempTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempTime = newDateTime; // 每次滾動更新時間
                    },
                  ),
                ),

                const SizedBox(height: 16),
                // 確定與取消按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), // 取消，回傳 null
                      child: const Text('取消', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () {
                        // 將 Cupertino 揀到嘅 DateTime 轉做 TimeOfDay 傳返出去
                        Navigator.pop(context, TimeOfDay.fromDateTime(tempTime));
                      },
                      child: const Text('確定', style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (pickedTime == null) return;

    // === 第三部分：將選中的日期與時間合併 (完全無改動) ===
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