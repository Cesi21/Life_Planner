import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/routine.dart';

class BackupService {
  Future<String> exportAll() async {
    final taskBox = Hive.box<Task>('tasks');
    final routineBox = Hive.box<Routine>('routines');
    final streakBox = Hive.box('routine_streaks');
    final data = {
      'tasks': taskBox.values.map((t) => {
        'title': t.title,
        'date': t.date.toIso8601String(),
        'isCompleted': t.isCompleted,
        'tag': t.tag,
        'reminderMinutes': t.reminderMinutes,
      }).toList(),
      'routines': routineBox.values.map((r) => {
        'title': r.title,
        'repeatType': r.repeatType.index,
        'weekdays': r.weekdays,
        'timeMinutes': r.timeMinutes,
        'isActive': r.isActive,
        'durationMinutes': r.durationMinutes,
      }).toList(),
      'streaks': streakBox.toMap(),
    };
    return jsonEncode(data);
  }

  Future<void> importAll(String jsonString) async {
    final data = jsonDecode(jsonString);
    final taskBox = Hive.box<Task>('tasks');
    final routineBox = Hive.box<Routine>('routines');
    final streakBox = Hive.box('routine_streaks');
    await taskBox.clear();
    await routineBox.clear();
    await streakBox.clear();
    for (final t in data['tasks']) {
      await taskBox.add(Task(
        title: t['title'],
        date: DateTime.parse(t['date']),
        isCompleted: t['isCompleted'],
        tag: t['tag'],
        reminderMinutes: t['reminderMinutes'],
      ));
    }
    for (final r in data['routines']) {
      await routineBox.add(Routine(
        title: r['title'],
        repeatType: RepeatType.values[r['repeatType']],
        weekdays: List<int>.from(r['weekdays']),
        timeMinutes: r['timeMinutes'],
        isActive: r['isActive'],
        durationMinutes: r['durationMinutes'],
      ));
    }
    final streaks = Map<String, dynamic>.from(data['streaks']);
    for (final key in streaks.keys) {
      await streakBox.put(key, streaks[key]);
    }
  }
}
