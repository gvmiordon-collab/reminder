import 'package:flutter/material.dart';
import 'calender_list.dart';

class Calender extends StatefulWidget {
  const Calender({super.key});

  @override
  State<Calender> createState() => _CalenderState();
}

class _CalenderState extends State<Calender> {
  @override
  Widget build(BuildContext context) {
    // No Center() here: CalenderList contains an Expanded/GridView that
    // wants to fill the available space. Center() only loosely constrains
    // its child, which can cause the grid to lay out oddly (or throw
    // "unbounded height/width" errors) depending on the widget tree above
    // it. Returning it directly lets the Scaffold body's bounded
    // constraints flow straight through.
    return const CalenderList();
  }
}