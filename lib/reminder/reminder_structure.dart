import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';


class ReminderStructure extends StatefulWidget {

  final String todo;
  final String date;  //暫時用文字先
  final VoidCallback? onDelete;
  final VoidCallback? onCheck;

  const ReminderStructure({
    super.key,
    required this.todo,
    required this.date,
    this.onCheck,
    this.onDelete,
  });


  @override
  State<ReminderStructure> createState() => _ReminderStructureState();
}

class _ReminderStructureState extends State<ReminderStructure> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Slidable(
        // Delete button
        endActionPane: ActionPane(
          motion: StretchMotion(),
          children:[
            SlidableAction(
              onPressed: (context) => widget.onDelete?.call(),
              icon: Icons.delete,
              backgroundColor: Colors.red,
            ),
          ],
        ),
        // task complete button
        startActionPane: ActionPane(
          motion: BehindMotion(),
          children:[
            SlidableAction(
              onPressed: (context) => widget.onCheck?.call(),
              icon: Icons.check,
              backgroundColor: Colors.lightGreenAccent,
            ),
          ],
        ),

        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(24),
          ),
          padding: EdgeInsets.all(24),
          child: Column(  ///
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.todo ,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              //
              const SizedBox(height: 8),
              //
              Text(
                widget.date,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
