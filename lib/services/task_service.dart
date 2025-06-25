import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TaskService {
  static const String boxName = 'tasks';

  Future<Box<Task>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Task>(boxName);
    }
    return await Hive.openBox<Task>(boxName);
  }

  Future<List<Task>> getTasksForDay(DateTime day, {String? tag}) async {
    final box = await _openBox();
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return box.values
        .where((t) => t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(end.add(const Duration(seconds: 1))) &&
            (tag == null || t.tag == tag))
        .toList();
  }

  Future<void> addTask(Task task) async {
    final box = await _openBox();
    await box.add(task);
  }

  Future<void> updateTask(Task task) async {
    await task.save();
  }

  Future<void> deleteTask(Task task) async {
    await task.delete();
  }
}
