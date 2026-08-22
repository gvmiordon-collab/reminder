import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reminder/reminder/my_button.dart';
import 'package:reminder/reminder/reminder_provider.dart';
import 'package:reminder/reminder/reminder_model.dart';


class DialogBox extends StatefulWidget {
  final Reminder? existingReminder; // 有傳入就係編輯模式,冇就係新增

  DialogBox({super.key, this.existingReminder});

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> {
  final _formKey = GlobalKey<FormState>();
  final _todocontrollor = TextEditingController();

  DateTime? _selectedDateTime;
  bool _hasTime = false; // 揀咗「唔設時間」就係 false
  bool _dateError = false; // 日期唔係 TextField,單獨用個 flag 控制紅框

  @override
  void initState() {
    super.initState();
    final existing = widget.existingReminder;
    if (existing != null) {
      _todocontrollor.text = existing.title;
      _selectedDateTime = existing.dueDate;
      _hasTime = existing.hasTime;
    }
  }

  @override
  void dispose() {
    _todocontrollor.dispose();
    super.dispose();
  }

  // 顯示格式,跟 _hasTime 決定使唔使加時間
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

    String dayLabel;
    if (targetDate == today) {
      dayLabel = "Today";
    } else if (targetDate == tomorrow) {
      dayLabel = "Tomorrow";
    } else {
      dayLabel = DateFormat('d MMM').format(_selectedDateTime!);
    }

    if (!_hasTime) return dayLabel; // 冇時間就淨顯示日期
    final timeStr = DateFormat('H:mm').format(_selectedDateTime!);
    return "$dayLabel, $timeStr";
  }

  Future<void> _pickDateTime(BuildContext context) async {
    // === 第一部分:日曆選擇器(無改動)===
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    // === 第二部分:時間選擇器,加多一個「唔設時間」掣 ===
    // 用 record 分辨 3 種結果:取消(null) / 唔設時間 / 揀咗時間
    final result = await showDialog<({bool hasTime, TimeOfDay? time})>(
      context: context,
      builder: (BuildContext context) {
        DateTime tempTime = _selectedDateTime ?? DateTime.now();

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            height: 300,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '選擇時間',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    initialDateTime: tempTime,
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempTime = newDateTime;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        (hasTime: false, time: null),
                      ),
                      child: const Text('唔設時間', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        (hasTime: true, time: TimeOfDay.fromDateTime(tempTime)),
                      ),
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

    if (result == null) return; // 撳咗「取消」,乜都唔改

    // === 第三部分:組合日期+時間(或者淨日期)===
    setState(() {
      _hasTime = result.hasTime;
      if (result.hasTime && result.time != null) {
        _selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          result.time!.hour,
          result.time!.minute,
        );
      } else {
        _selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
      }
      _dateError = false;
    });
  }

  void _handleConfirm() {
    final isTitleValid = _formKey.currentState?.validate() ?? false;
    final isDateValid = _selectedDateTime != null;

    setState(() => _dateError = !isDateValid);

    if (!isTitleValid || !isDateValid) return;

    final existing = widget.existingReminder;
    if (existing != null) {
      context.read<ReminderProvider>().editReminder(
        id: existing.id!,
        title: _todocontrollor.text.trim(),
        dueDate: _selectedDateTime!,
        hasTime: _hasTime,
      );
    } else {
      context.read<ReminderProvider>().addReminder(
        title: _todocontrollor.text.trim(),
        dueDate: _selectedDateTime!,
        hasTime: _hasTime,
      );
    }

    Navigator.pop(context);
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _todocontrollor,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'what you want to do?',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '請輸入標題';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),

              // 日期/時間選擇按鈕,_dateError 時顯示紅框
              InkWell(
                onTap: () => _pickDateTime(context),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _dateError ? Colors.red : Colors.black54,
                      width: _dateError ? 1.5 : 1.0,
                    ),
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
              if (_dateError)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '請選擇日期',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    MyButton(
                    name: widget.existingReminder == null ? 'confirm' : 'save',
                    onPressed: _handleConfirm,
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(width: 8.0),
                  MyButton(
                    name: 'cancel',
                    onPressed: () => Navigator.pop(context),
                    color: Colors.orangeAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  改咗啲乜:
// _hasTime 由「唔設時間」掣控制,formattedText 同 database schema(hasTime)一致
// TextField → TextFormField 包喺 Form 入面,標題空白會自動彈紅框+文字
// 日期格用 _dateError 控制紅框,撳 confirm 先檢查
// _handleConfirm 兩個都過先 call ReminderProvider.addReminder(...),然後關閉 dialog