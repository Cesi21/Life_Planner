import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:planner/models/task.dart';
import 'package:planner/models/routine.dart';
import 'package:planner/models/tag.dart';
import 'package:planner/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(RepeatTypeAdapter());
    Hive.registerAdapter(RoutineAdapter());
    Hive.registerAdapter(TagAdapter());
    await Hive.openBox<Task>('tasks');
    await Hive.openBox<Routine>('routines');
    await Hive.openBox<Map>('routine_done');
    await Hive.openBox('routine_streaks');
    await Hive.openBox<Tag>('tags');
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('tasks');
    await Hive.deleteBoxFromDisk('routines');
    await Hive.deleteBoxFromDisk('routine_done');
    await Hive.deleteBoxFromDisk('routine_streaks');
    await Hive.deleteBoxFromDisk('tags');
  });

  test('export and import', () async {
    final taskBox = Hive.box<Task>('tasks');
    await taskBox.add(Task(title: 't', date: DateTime(2020)));

    final path = await BackupService().exportAll();
    final file = File(path);
    expect(await file.exists(), true);

    await taskBox.clear();
    await BackupService().importAll(file);
    expect(taskBox.length, 1);
  });
}
