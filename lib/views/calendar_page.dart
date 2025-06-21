import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';
import '../models/routine.dart';
import '../services/task_service.dart';
import '../services/routine_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TaskService _service = TaskService();
  final RoutineService _routineService = RoutineService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Task> _tasks = [];
  List<Routine> _routines = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_selectedDay == null) return;
    final tasks = await _service.getTasksForDay(_selectedDay!);
    final routines = (await _routineService.getRoutines())
        .where((r) => r.isActive && r.weekdays.contains(_selectedDay!.weekday))
        .toList();
    setState(() {
      _tasks = tasks;
      _routines = routines;
    });
  }

  Future<void> _addTask() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final task = Task(title: result, date: _selectedDay!);
      await _service.addTask(task);
      _loadData();
    }
  }

  Widget _buildTaskItem(Task task) {
    return CheckboxListTile(
      title: Text(task.title),
      value: task.isCompleted,
      onChanged: (value) async {
        task.isCompleted = value ?? false;
        await _service.updateTask(task);
        _loadData();
      },
    );
  }

  Widget _buildRoutineItem(Routine routine) {
    return ListTile(
      leading: const Icon(Icons.repeat, color: Colors.blue),
      title: Text(routine.title),
      subtitle: routine.time == null ? null : Text(routine.time!.format(context)),
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
          Expanded(
            child: ListView(
              children: [
                ..._routines.map(_buildRoutineItem),
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
