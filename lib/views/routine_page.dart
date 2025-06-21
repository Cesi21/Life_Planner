import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../services/routine_service.dart';

class RoutinePage extends StatefulWidget {
  const RoutinePage({super.key});

  @override
  State<RoutinePage> createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  final RoutineService _service = RoutineService();
  List<Routine> _routines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final routines = await _service.getRoutines();
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final r = Routine(title: result, weekdays: [], isActive: true);
      await _service.addRoutine(r);
      _load();
    }
  }

  Widget _buildWeekdayCheckbox(Routine routine, int day) {
    return Expanded(
      child: CheckboxListTile(
        dense: true,
        title: Text(['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][day-1], style: const TextStyle(fontSize: 12)),
        value: routine.weekdays.contains(day),
        onChanged: (val) async {
          if (val == true) {
            routine.weekdays.add(day);
          } else {
            routine.weekdays.remove(day);
          }
          await _service.updateRoutine(routine);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildRoutineItem(Routine routine) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(routine.title),
            trailing: Switch(
              value: routine.isActive,
              onChanged: (val) async {
                routine.isActive = val;
                await _service.updateRoutine(routine);
                setState(() {});
              },
            ),
            onLongPress: () async {
              await _service.deleteRoutine(routine);
              _load();
            },
          ),
          Row(
            children: List.generate(7, (index) => _buildWeekdayCheckbox(routine, index + 1)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      body: ListView(
        children: _routines.map(_buildRoutineItem).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRoutine,
        child: const Icon(Icons.add),
      ),
    );
  }
}
