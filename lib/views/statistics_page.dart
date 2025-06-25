import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/task_service.dart';
import '../services/routine_service.dart';
import '../models/routine.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final TaskService _taskService = TaskService();
  final RoutineService _routineService = RoutineService();

  Map<DateTime, double> _weekly = {};
  Map<Routine, String> _routineStats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final Map<DateTime, double> completion = {};
    final routines = await _routineService.getRoutines();
    final Map<Routine, int> done = {for (var r in routines) r: 0};
    final Map<Routine, int> total = {for (var r in routines) r: 0};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final tasks = await _taskService.getTasksForDay(day);
      final dayRoutines = await _routineService.getRoutinesForDay(day);
      int totalCount = tasks.length + dayRoutines.length;
      int doneCount = tasks.where((t) => t.isCompleted).length;
      for (final r in dayRoutines) {
        final c = await _routineService.isCompleted(r, day);
        if (c) done[r] = done[r]! + 1;
        if (r.weekdays.contains(day.weekday)) total[r] = total[r]! + 1;
        if (c) doneCount++;
      }
      completion[day] = totalCount == 0 ? 0 : doneCount / totalCount * 100;
    }
    final routineStats = {for (var r in routines) r: '${done[r]}/${total[r]}'};
    setState(() {
      _weekly = completion;
      _routineStats = routineStats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: 100,
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final date = _weekly.keys.elementAt(value.toInt());
                        return Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(_weekly.length, (index) {
                  final percent = _weekly.values.elementAt(index);
                  return BarChartGroupData(x: index, barRods: [BarChartRodData(toY: percent)]);
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Routine Consistency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ..._routineStats.entries.map((e) => ListTile(
                title: Text(e.key.title),
                trailing: Text(e.value),
              )),
        ],
      ),
    );
  }
}
