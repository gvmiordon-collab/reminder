import 'package:flutter/material.dart';
import 'package:reminder/main_screen.dart';

void main() {
  runApp(const Reminder());
}

class Reminder extends StatelessWidget {
  const Reminder({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
        home: MainScreen(),
      );
  }
}
