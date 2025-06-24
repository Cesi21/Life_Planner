import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/task_service.dart';
//import '../models/task.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final TaskService _service = TaskService();
  Map<DateTime, int> _completed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final data = <DateTime, int>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final tasks = await _service.getTasksForDay(day);
      data[day] = tasks.where((t) => t.isCompleted).length;
    }
    setState(() => _completed = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final date = _completed.keys.elementAt(value.toInt());
                    return Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
            ),
            barGroups: List.generate(_completed.length, (index) {
              final count = _completed.values.elementAt(index);
              return BarChartGroupData(x: index, barRods: [BarChartRodData(toY: count.toDouble())]);
            }),
          ),
        ),
      ),
    );
  }
}
