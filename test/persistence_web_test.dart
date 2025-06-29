import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:planner/models/task.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    await Hive.openBox<Task>('tasks');
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('tasks');
  });

  test('persist task across box reopen', () async {
    final box = Hive.box<Task>('tasks');
    await box.add(Task(title: 't', date: DateTime(2020)));
    await box.close();
    await Hive.openBox<Task>('tasks');
    final reopened = Hive.box<Task>('tasks');
    expect(reopened.length, 1);
    expect(reopened.values.first.title, 't');
  });
}
