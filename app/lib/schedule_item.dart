import 'package:flutter/material.dart';

class ScheduleItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final ValueChanged<bool?> onToggle;

  ScheduleItem({
    required this.title,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: onToggle,
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
