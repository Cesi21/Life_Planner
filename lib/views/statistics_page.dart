import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/stats_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late final StatsService _stats;

  @override
  void initState() {
    super.initState();
    _stats = StatsService();
  }

  @override
  void dispose() {
    _stats.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _stats,
      builder: (context, _) {
        final weekly = _stats.weekly;
        return Scaffold(
          appBar: AppBar(title: const Text('Statistics')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: const Text('Completed Today'),
                trailing: Text('${_stats.completedToday}'),
              ),
              ListTile(
                title: const Text('Minutes Spent on Routines Today'),
                trailing:
                    Text('${_stats.timeSpentToday.inMinutes}m'),
              ),
              const SizedBox(height: 16),
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
                            final date = weekly.keys.elementAt(value.toInt());
                            return Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    barGroups: List.generate(weekly.length, (index) {
                      final percent = weekly.values.elementAt(index);
                      return BarChartGroupData(x: index, barRods: [BarChartRodData(toY: percent)]);
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final date =
                                _stats.minutesSpent.keys.elementAt(value.toInt());
                            return Text('${date.month}/${date.day}',
                                style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        color: Colors.blue,
                        spots: List.generate(
                          _stats.tasksCompleted.length,
                          (i) => FlSpot(
                              i.toDouble(),
                              _stats.tasksCompleted.values.elementAt(i).toDouble()),
                        ),
                      ),
                      LineChartBarData(
                        color: Colors.red,
                        spots: List.generate(
                          _stats.minutesSpent.length,
                          (i) => FlSpot(
                              i.toDouble(),
                              _stats.minutesSpent.values.elementAt(i).toDouble()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Routine Consistency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ..._stats.routineStats.entries.map(
                (e) => ListTile(
                  title: Text(e.key.title),
                  trailing: Text(e.value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
