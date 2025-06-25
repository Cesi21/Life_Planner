import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import 'i_task_service.dart';

class TaskService implements ITaskService {
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

  Future<void> moveIncompleteTasksToToday() async {
    final box = await _openBox();
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    for (final task in box.values) {
      final day = DateTime(task.date.year, task.date.month, task.date.day);
      if (day == yesterday && !task.isCompleted) {
        task.date = now;
        await task.save();
      }
    }
  }
}
