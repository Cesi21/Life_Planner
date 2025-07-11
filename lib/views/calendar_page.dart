import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/task_service.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';
import '../services/notification_service.dart';
import '../services/tag_service.dart';
import '../models/tag.dart';
import '../widgets/task_tile.dart';
import '../widgets/date_selector.dart';
import '../widgets/routine_tile.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TaskService _service = TaskService();
  final RoutineService _routineService = RoutineService();
  final TagService _tagService = TagService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Task> _tasks = [];
  int _routineCount = 0;
  List<Routine> _routines = [];
  final Map<int, bool> _routineDone = {};
  String? _selectedTagId;
  List<Tag> _availableTags = [];
  bool _successShown = false;
  late final ValueListenable _routineListenable;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _routineListenable = Hive.box<Routine>('routines').listenable();
    _routineListenable.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    _routineListenable.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_selectedDay == null) return;
    final tasks =
        await _service.getTasksForDay(_selectedDay!, tagId: _selectedTagId);
    final routines =
        await _routineService.getRoutinesForDay(_selectedDay!, tagId: _selectedTagId);
    final Map<int, bool> doneMap = {};
    for (final r in routines) {
      doneMap[r.key as int] =
          await _routineService.isRoutineDone(r.key.toString(), _selectedDay!);
    }
    final tags = await _tagService.getAllTags();
    setState(() {
      _tasks = tasks;
      _routineCount = routines.length;
      _routines = routines;
      _routineDone
        ..clear()
        ..addAll(doneMap);
      _availableTags = tags;
    });
    final allDone = _routineDone.values.every((d) => d) && _routines.isNotEmpty;
    if (mounted) {
      if (allDone && !_successShown) {
        _successShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Great job! All routines done for today.')),
        );
      } else if (!allDone) {
        _successShown = false;
      }
    }
  }

  Future<void> _openTaskForm({Task? task}) async {
    final titleController = TextEditingController(text: task?.title ?? '');
    String? tagId = task?.tagId;
    TimeOfDay? reminder = task?.reminderTime;
    final tags = await _tagService.getAllTags();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(task == null ? 'New Task' : 'Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              DropdownButtonFormField<String>(
                value: tagId,
                decoration: const InputDecoration(labelText: 'Tag'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...tags.map((t) => DropdownMenuItem(
                        value: t.key.toString(),
                        child: Text(t.name),
                      )),
                ],
                onChanged: (val) => setStateDialog(() => tagId = val),
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
              child: Text(task == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      if (task == null) {
        final newTask = Task(
          title: titleController.text,
          date: _selectedDay!,
          tagId: tagId,
        );
        newTask.reminderTime = reminder;
        await _service.addTask(newTask);
        await NotificationService().scheduleTaskReminder(newTask);
      } else {
        task.title = titleController.text;
        task.tagId = tagId;
        task.reminderTime = reminder;
        await _service.updateTask(task);
        await NotificationService().scheduleTaskReminder(task);
      }
      _loadData();
    }
  }

  Widget _buildTaskItem(Task task) {
    final baseColor = Colors.greenAccent;
    return Card(
      color: baseColor.withAlpha((baseColor.alpha * 0.1).round()),
      child: TaskTile(
        task: task,
        onCompleted: (_) => _loadData(),
        onEdit: () => _openTaskForm(task: task),
        onDelete: () async {
          await _service.deleteTask(task);
          _loadData();
        },
      ),
    );
  }

  Widget _buildRoutineItem(Routine r) {
    final done = _routineDone[r.key as int] ?? false;
    return RoutineTile(
      routine: r,
      completed: done,
      date: _selectedDay!,
      onCompleted: (_) => _loadData(),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planner')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Builder(
                  builder: (context) {
                    final total = _tasks.length + _routineCount;
                    final completed =
                        _tasks.where((t) => t.isCompleted).length +
                            _routineDone.values.where((d) => d).length;
                    final progress = total == 0 ? 0.0 : completed / total;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Completed $completed of $total items today'),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: progress),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: DateSelector(
                  selected: _selectedDay!,
                  onChanged: (d) {
                    setState(() {
                      _selectedDay = d;
                      _focusedDay = d;
                    });
                    _loadData();
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  final today = DateTime.now();
                  setState(() {
                    _selectedDay = today;
                    _focusedDay = today;
                  });
                  _loadData();
                },
                child: const Text('Today'),
              ),
            ],
          ),
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
                DropdownButton<String?>(
                  value: _selectedTagId,
                  hint: const Text('All'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All')),
                    ..._availableTags.map(
                      (t) => DropdownMenuItem(
                        value: t.key.toString(),
                        child: Text(t.name),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedTagId = val);
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
              if (_routines.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Routines', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ..._routines.map(_buildRoutineItem),
            ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add',
        onPressed: () => _openTaskForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
