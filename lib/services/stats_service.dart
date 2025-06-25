import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/routine.dart';

class StatsService extends ChangeNotifier {
  late final Box<Task> _taskBox;
  late final Box<Routine> _routineBox;
  late final Box<List> _completionBox;

  late final ValueListenable _taskListenable;
  late final ValueListenable _routineListenable;
  late final ValueListenable _completionListenable;

  Map<DateTime, double> weekly = {};
  Map<Routine, String> routineStats = {};
  int completedToday = 0;
  Duration timeSpentToday = Duration.zero;

  StatsService() {
    _taskBox = Hive.box<Task>('tasks');
    _routineBox = Hive.box<Routine>('routines');
    _completionBox = Hive.box<List>('routine_done');

    _taskListenable = _taskBox.listenable();
    _routineListenable = _routineBox.listenable();
    _completionListenable = _completionBox.listenable();

    _taskListenable.addListener(_calculate);
    _routineListenable.addListener(_calculate);
    _completionListenable.addListener(_calculate);

    _calculate();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _routineDone(Routine r, DateTime date) {
    final key = DateTime(date.year, date.month, date.day).toIso8601String();
    final list = List<String>.from(
        _completionBox.get(key, defaultValue: <String>[]) as List);
    return list.contains(r.key.toString());
  }

  void _calculate() {
    final now = DateTime.now();
    final routines = _routineBox.values.toList();

    final Map<Routine, int> doneCounts = {for (var r in routines) r: 0};
    final Map<Routine, int> totalCounts = {for (var r in routines) r: 0};
    final Map<DateTime, double> completion = {};

    completedToday = 0;
    timeSpentToday = Duration.zero;

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final tasks = _taskBox.values.where((t) => _sameDay(t.date, day)).toList();
      final dayRoutines = routines
          .where((r) => r.isActive && r.weekdays.contains(day.weekday))
          .toList();

      int total = tasks.length + dayRoutines.length;
      int done = tasks.where((t) => t.isCompleted).length;

      for (final r in dayRoutines) {
        final d = _routineDone(r, day);
        if (d) {
          doneCounts[r] = doneCounts[r]! + 1;
          done++;
          if (_sameDay(day, now)) {
            completedToday++;
            if (r.duration != null) {
              timeSpentToday += r.duration!;
            }
          }
        }
        if (r.weekdays.contains(day.weekday)) {
          totalCounts[r] = totalCounts[r]! + 1;
        }
      }

      if (_sameDay(day, now)) {
        completedToday += tasks.where((t) => t.isCompleted).length;
      }

      completion[day] = total == 0 ? 0 : done / total * 100;
    }

    weekly = completion;
    routineStats = {
      for (var r in routines) r: '${doneCounts[r]}/${totalCounts[r]}'
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _taskListenable.removeListener(_calculate);
    _routineListenable.removeListener(_calculate);
    _completionListenable.removeListener(_calculate);
    super.dispose();
  }
}
