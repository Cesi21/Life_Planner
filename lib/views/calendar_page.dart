import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final RoutineService _service = RoutineService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Routine> _routines = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    if (_selectedDay == null) return;
    final routines = await _service.getRoutinesForDay(_selectedDay!);
    setState(() {
      _routines = routines;
    });
  }

  Future<void> _addRoutine() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Routine'),
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
      final routine = Routine(title: result, date: _selectedDay!);
      await _service.addRoutine(routine);
      _loadRoutines();
    }
  }

  Widget _buildRoutineItem(Routine routine) {
    return CheckboxListTile(
      title: Text(routine.title),
      value: routine.isCompleted,
      onChanged: (value) async {
        routine.isCompleted = value ?? false;
        await _service.updateRoutine(routine);
        _loadRoutines();
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
              _loadRoutines();
            },
          ),
          Expanded(
            child: ListView(
              children: _routines.map(_buildRoutineItem).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRoutine,
        child: const Icon(Icons.add),
      ),
    );
  }
}
