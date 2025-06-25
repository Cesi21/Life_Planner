import "../models/task.dart";
abstract class ITaskService {
  Future<List<Task>> getTasksForDay(DateTime day, {String? tag});
  Future<void> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(Task task);
}
