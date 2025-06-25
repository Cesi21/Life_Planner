import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine.dart';
import 'i_routine_service.dart';
import 'notification_service.dart';

class RoutineService implements IRoutineService {
  static const String boxName = 'routines';
  static const String completionBox = 'routine_done';
  static const String streakBox = 'routine_streaks';

  static final Map<String, int> _pausedRemaining = {};

  Future<Box<Routine>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Routine>(boxName);
    }
    return await Hive.openBox<Routine>(boxName);
  }

  Future<Box<Map>> _openCompletionBox() async {
    if (Hive.isBoxOpen(completionBox)) {
      return Hive.box<Map>(completionBox);
    }
    return await Hive.openBox<Map>(completionBox);
  }

  Future<Box<Map>> _openStreakBox() async {
    if (Hive.isBoxOpen(streakBox)) {
      return Hive.box<Map>(streakBox);
    }
    return await Hive.openBox<Map>(streakBox);
  }

  Future<List<Routine>> getRoutines() async {
    final box = await _openBox();
    return box.values.toList();
  }

  String _dateKey(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();

  Future<bool> isRoutineDone(String routineKey, DateTime date) async {
    final box = await _openCompletionBox();
    final key = _dateKey(date);
    final map = Map<String, bool>.from(box.get(key, defaultValue: {}) as Map);
    return map[routineKey] ?? false;
  }

  Future<void> trackStreak(String routineKey, DateTime date, bool completed) async {
    final box = await _openStreakBox();
    final data = Map<String, dynamic>.from(box.get(routineKey, defaultValue: {
      'current': 0,
      'longest': 0,
      'last': null,
    }) as Map);

    final lastStr = data['last'] as String?;
    final last = lastStr == null ? null : DateTime.tryParse(lastStr);

    final day = DateTime(date.year, date.month, date.day);
    if (completed) {
      if (last != null && day.difference(last).inDays == 1) {
        data['current'] = (data['current'] as int) + 1;
      } else if (last == null || day.isAfter(last)) {
        data['current'] = 1;
      }
      if (data['current'] > (data['longest'] as int)) {
        data['longest'] = data['current'];
      }
      data['last'] = day.toIso8601String();
    } else {
      if (last != null && day.isAtSameMomentAs(last)) {
        data['current'] = (data['current'] as int) - 1;
        if (data['current'] < 0) data['current'] = 0;
        data['last'] = null;
      }
    }
    await box.put(routineKey, data);
  }

  Future<int> getCurrentStreak(String routineKey) async {
    final box = await _openStreakBox();
    final data = box.get(routineKey);
    return data == null ? 0 : (data['current'] as int? ?? 0);
  }

  Future<int> getLongestStreak(String routineKey) async {
    final box = await _openStreakBox();
    final data = box.get(routineKey);
    return data == null ? 0 : (data['longest'] as int? ?? 0);
  }

  void saveRemaining(String routineKey, int seconds) {
    _pausedRemaining[routineKey] = seconds;
  }

  int? getRemaining(String routineKey) => _pausedRemaining[routineKey];

  void clearRemaining(String routineKey) {
    _pausedRemaining.remove(routineKey);
  }

  Future<void> markRoutineDone(String routineKey, DateTime date) async {
    final box = await _openCompletionBox();
    final key = _dateKey(date);
    final map = Map<String, bool>.from(box.get(key, defaultValue: {}) as Map);
    map[routineKey] = true;
    await box.put(key, map);
    await trackStreak(routineKey, date, true);
  }

  Future<void> unmarkRoutineDone(String routineKey, DateTime date) async {
    final box = await _openCompletionBox();
    final key = _dateKey(date);
    final map = Map<String, bool>.from(box.get(key, defaultValue: {}) as Map);
    if (map.containsKey(routineKey)) {
      map[routineKey] = false;
    }
    await box.put(key, map);
    await trackStreak(routineKey, date, false);
  }

  Future<List<Routine>> getRoutinesForDay(DateTime day, {String? tagId}) async {
    final box = await _openBox();
    final weekday = day.weekday;
    return box.values
        .where((r) =>
            r.isActive &&
            r.weekdays.contains(weekday) &&
            (tagId == null || r.tagId == tagId))
        .toList();
  }

  Future<void> addRoutine(Routine routine) async {
    final box = await _openBox();
    await box.add(routine);
    await NotificationService()
        .scheduleRoutineReminder(routine, DateTime.now());
  }

  Future<void> updateRoutine(Routine routine) async {
    await routine.save();
    await NotificationService()
        .scheduleRoutineReminder(routine, DateTime.now());
  }

  Future<void> deleteRoutine(Routine routine) async {
    await NotificationService().cancelRoutineReminder(routine.key.toString());
    await routine.delete();
  }

  Future<void> toggleComplete(
      Routine routine, DateTime day, bool done) async {
    if (done) {
      await markRoutineDone(routine.key.toString(), day);
    } else {
      await unmarkRoutineDone(routine.key.toString(), day);
    }
  }

  @override
  Future<void> markCompleted(Routine routine, DateTime day, bool done) async {
    if (done) {
      await markRoutineDone(routine.key.toString(), day);
    } else {
      await unmarkRoutineDone(routine.key.toString(), day);
    }
    await trackStreak(routine.key.toString(), day, done);
  }

  @override
  Future<bool> isCompleted(Routine routine, DateTime day) async {
    return isRoutineDone(routine.key.toString(), day);
  }
}
