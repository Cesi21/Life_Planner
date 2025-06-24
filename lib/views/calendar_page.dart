import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TaskService _service = TaskService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Task> _tasks = [];
  String? _selectedTag;
  List<String> _availableTags = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_selectedDay == null) return;
    final tasks = await _service.getTasksForDay(_selectedDay!, tag: _selectedTag);
    final all = await _service.getTasksForDay(_selectedDay!);
    final tags = <String>{};
    for (final t in all) {
      if (t.tag != null) tags.add(t.tag!);
    }
    setState(() {
      _tasks = tasks;
      _availableTags = tags.toList();
    });
  }

  Future<void> _addTask() async {
    final titleController = TextEditingController();
    final tagController = TextEditingController();
    TimeOfDay? reminder;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(labelText: 'Tag'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Reminder:'),
                  const SizedBox(width: 8),
                  Text(reminder == null ? 'None' : reminder!.format(context)),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setStateDialog(() => reminder = picked);
                      }
                    },
                    child: const Text('Select'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      final task = Task(
        title: titleController.text,
        date: _selectedDay!,
        tag: tagController.text.isEmpty ? null : tagController.text,
      );
      task.reminderTime = reminder;
      await _service.addTask(task);
      await NotificationService().scheduleTask(task);
      _loadData();
    }
  }

  Widget _buildTaskItem(Task task) {
    final textStyle = task.isCompleted
        ? const TextStyle(decoration: TextDecoration.lineThrough)
        : null;
    return CheckboxListTile(
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
        ],
      ),
      value: task.isCompleted,
      onChanged: (value) async {
        task.isCompleted = value ?? false;
        await _service.updateTask(task);
        _loadData();
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planner')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(day, _selectedDay),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadData();
            },
          ),
        if (_availableTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Tag:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedTag,
                  hint: const Text('All'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._availableTags.map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedTag = val);
                    _loadData();
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            children: [
              ..._tasks.map(_buildTaskItem),
            ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
