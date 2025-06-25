import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:planner/models/task.dart';
import 'package:planner/services/task_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>('tasks');
  });

  tearDown(() async {
    final box = Hive.box<Task>('tasks');
    await box.clear();
    await box.close();
  });

  test('add and fetch task', () async {
    final service = TaskService();
    final task = Task(title: 'test', date: DateTime(2020));
    await service.addTask(task);

    final tasks = await service.getTasksForDay(DateTime(2020));
    expect(tasks.length, 1);
    expect(tasks.first.title, 'test');
  });
}
