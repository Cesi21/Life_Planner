import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine.dart';
import 'i_routine_service.dart';
import 'notification_service.dart';

class RoutineService implements IRoutineService {
  static const String boxName = 'routines';
  static const String completionBox = 'routine_done';

  Future<Box<Routine>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Routine>(boxName);
    }
    return await Hive.openBox<Routine>(boxName);
  }

  Future<Box<List>> _openCompletionBox() async {
    if (Hive.isBoxOpen(completionBox)) {
      return Hive.box<List>(completionBox);
    }
    return await Hive.openBox<List>(completionBox);
  }

  Future<List<Routine>> getRoutines() async {
    final box = await _openBox();
    return box.values.toList();
  }

  String _dateKey(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();

  Future<bool> isRoutineDone(String routineKey, DateTime date) async {
    final box = await _openCompletionBox();
    final key = _dateKey(date);
    final list = List<String>.from(box.get(key, defaultValue: <String>[]) as List);
    return list.contains(routineKey);
  }

  Future<void> markRoutineDone(String routineKey, DateTime date) async {
    final box = await _openCompletionBox();
    final key = _dateKey(date);
    final list = List<String>.from(box.get(key, defaultValue: <String>[]) as List);
    if (!list.contains(routineKey)) list.add(routineKey);
    await box.put(key, list);
  }

  Future<void> unmarkRoutineDone(String routineKey, DateTime date) async {
    final box = await _openCompletionBox();
    final key = _dateKey(date);
    final list = List<String>.from(box.get(key, defaultValue: <String>[]) as List);
    list.remove(routineKey);
    await box.put(key, list);
  }

  Future<List<Routine>> getRoutinesForDay(DateTime day) async {
    final box = await _openBox();
    final weekday = day.weekday;
    return box.values
        .where((r) => r.isActive && r.weekdays.contains(weekday))
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

  @override
  Future<void> markCompleted(Routine routine, DateTime day, bool done) async {
    if (done) {
      await markRoutineDone(routine.key.toString(), day);
    } else {
      await unmarkRoutineDone(routine.key.toString(), day);
    }
  }

  @override
  Future<bool> isCompleted(Routine routine, DateTime day) async {
    return isRoutineDone(routine.key.toString(), day);
  }
}
