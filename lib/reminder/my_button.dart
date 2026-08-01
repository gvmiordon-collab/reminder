import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String name;
  final VoidCallback? onPressed;
  final Color color;

   MyButton({
    super.key,
    required this.name,
    this.onPressed,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(name),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
      ),
    );
  }
}
