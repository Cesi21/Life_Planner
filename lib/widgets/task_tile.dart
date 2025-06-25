import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/tag_service.dart';
import '../services/task_service.dart';

class TaskTile extends StatefulWidget {
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
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  final TaskService _taskSvc = TaskService();
  late ValueNotifier<bool> _done;

  @override
  void initState() {
    super.initState();
    _done = ValueNotifier(widget.task.isCompleted);
  }

  @override
  void didUpdateWidget(covariant TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.isCompleted != widget.task.isCompleted) {
      _done.value = widget.task.isCompleted;
    }
  }

  @override
  void dispose() {
    _done.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tag = widget.task.tagId == null
        ? null
        : TagService().getTagById(widget.task.tagId!);
    return Dismissible(
      key: ValueKey(widget.task.key),
      direction: widget.onDelete == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDelete?.call(),
      child: ValueListenableBuilder<bool>(
        valueListenable: _done,
        builder: (_, done, __) {
          final style = done
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null;
          return CheckboxListTile(
            title: Row(
              children: [
                Expanded(child: Text(widget.task.title, style: style)),
                if (tag != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: () {
                        final c = tag.color;
                        return c.withAlpha((c.alpha * 0.2).round());
                      }(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Text(tag.name, style: const TextStyle(fontSize: 12)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: widget.onEdit,
                )
              ],
            ),
            value: done,
            onChanged: (val) async {
              await _taskSvc.toggleComplete(widget.task, val ?? false);
              _done.value = val ?? false;
              widget.onCompleted?.call(val);
            },
          );
        },
      ),
    );
  }
}
