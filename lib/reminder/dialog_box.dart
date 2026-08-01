import 'package:flutter/material.dart';
import 'package:reminder/reminder/my_button.dart';

class DialogBox extends StatefulWidget {
   DialogBox({super.key});

  @override
  State<DialogBox> createState() => _DialogBoxState();
}

class _DialogBoxState extends State<DialogBox> {
  final _todocontrollor = TextEditingController();
  final _datecontroller = TextEditingController();


  @override
  void dispose() {
    _todocontrollor.dispose();
    _datecontroller.dispose();
    super.dispose();
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
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _todocontrollor,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'what you want to do?'
              ),
            ),
            SizedBox(
              height: 6.0,
            ),
            TextField(
              controller: _datecontroller,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'dealing'
              ),
            ),
            SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MyButton(name: 'confirm', onPressed: () {}, color: Colors.tealAccent),
                SizedBox(width: 8.0,),
                MyButton(name: 'cancel', onPressed: () => Navigator.pop(context), color: Colors.orangeAccent)
              ],
            )
          ],
        ),
      ),
    );
  }
}
