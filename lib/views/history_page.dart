import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/routine.dart';
import '../services/task_service.dart';
import '../services/routine_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TaskService _taskService = TaskService();
  final RoutineService _routineService = RoutineService();

  String _search = '';
  String _filter = 'all';
  Map<DateTime, List<Widget>> _items = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final Map<DateTime, List<Widget>> result = {};
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final tasks = await _taskService.getTasksForDay(day);
      final routines = await _routineService.getRoutinesForDay(day);
      final widgets = <Widget>[];
      for (final t in tasks.where((t) => t.isCompleted)) {
        if (_filter != 'routines' && t.title.toLowerCase().contains(_search)) {
          widgets.add(ListTile(title: Text(t.title)));
        }
      }
      for (final r in routines) {
        final done = await _routineService.isRoutineDone(r.key.toString(), day);
        if (done && _filter != 'tasks' && r.title.toLowerCase().contains(_search)) {
          widgets.add(ListTile(
            title: Text(r.title),
            subtitle: r.duration != null ? Text('${r.duration!.inMinutes}m') : null,
          ));
        }
      }
      if (widgets.isNotEmpty) {
        result[day] = widgets;
      }
    }
    setState(() => _items = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(labelText: 'Search'),
              onChanged: (v) {
                _search = v.toLowerCase();
                _load();
              },
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _filter == 'all',
                onSelected: (_) {
                  setState(() => _filter = 'all');
                  _load();
                },
              ),
              ChoiceChip(
                label: const Text('Tasks'),
                selected: _filter == 'tasks',
                onSelected: (_) {
                  setState(() => _filter = 'tasks');
                  _load();
                },
              ),
              ChoiceChip(
                label: const Text('Routines'),
                selected: _filter == 'routines',
                onSelected: (_) {
                  setState(() => _filter = 'routines');
                  _load();
                },
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: _items.entries.map((e) {
                final date = e.key;
                final label = '${['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][date.weekday-1]} ${date.day} ${_month(date.month)}';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...e.value,
                    const Divider(),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _month(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}
