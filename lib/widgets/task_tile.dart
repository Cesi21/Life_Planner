import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?>? onCompleted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    this.onCompleted,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = task.isCompleted
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    return Dismissible(
      key: ValueKey(task.key),
      direction: onDelete == null ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: CheckboxListTile(
        title: Row(
          children: [
            Expanded(child: Text(task.title, style: textStyle)),
            if (task.tag != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(task.tag!, style: const TextStyle(fontSize: 12)),
              ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: onEdit,
            )
          ],
        ),
        value: task.isCompleted,
        onChanged: onCompleted,
      ),
    );
  }
}
