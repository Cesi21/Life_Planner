import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine.dart';
import 'i_routine_service.dart';

class RoutineService implements IRoutineService {
  static const String boxName = 'routines';
  static const String completionBox = 'routineCompletions';

  Future<Box<Routine>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Routine>(boxName);
    }
    return await Hive.openBox<Routine>(boxName);
  }

  Future<Box> _openCompletionBox() async {
    if (Hive.isBoxOpen(completionBox)) {
      return Hive.box(completionBox);
    }
    return await Hive.openBox(completionBox);
  }

  Future<List<Routine>> getRoutines() async {
    final box = await _openBox();
    return box.values.toList();
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
  }

  Future<void> updateRoutine(Routine routine) async {
    await routine.save();
  }

  Future<void> deleteRoutine(Routine routine) async {
    await routine.delete();
  }

  @override
  Future<void> markCompleted(Routine routine, DateTime day, bool done) async {
    final box = await _openCompletionBox();
    final key = routine.key.toString();
    final dateStr = DateTime(day.year, day.month, day.day).toIso8601String();
    final list = List<String>.from(box.get(key, defaultValue: <String>[]) as List);
    if (done) {
      if (!list.contains(dateStr)) list.add(dateStr);
    } else {
      list.remove(dateStr);
    }
    await box.put(key, list);
  }

  @override
  Future<bool> isCompleted(Routine routine, DateTime day) async {
    final box = await _openCompletionBox();
    final key = routine.key.toString();
    final dateStr = DateTime(day.year, day.month, day.day).toIso8601String();
    final list = List<String>.from(box.get(key, defaultValue: <String>[]) as List);
    return list.contains(dateStr);
  }
}
