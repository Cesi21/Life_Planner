import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:planner/models/task.dart';
import 'package:planner/services/task_service.dart';
import 'package:planner/widgets/task_tile.dart';
import 'package:flutter/material.dart';

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

  testWidgets('toggling one task does not affect others', (tester) async {
    final service = TaskService();
    final t1 = Task(title: 'A', date: DateTime(2020));
    final t2 = Task(title: 'B', date: DateTime(2020));
    await service.addTask(t1);
    await service.addTask(t2);

    await tester.pumpWidget(MaterialApp(
      home: Column(
        children: [
          TaskTile(task: t1),
          TaskTile(task: t2),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(t1.isCompleted, true);
    expect(t2.isCompleted, false);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(t1.isCompleted, false);
    expect(t2.isCompleted, false);
  });
}
