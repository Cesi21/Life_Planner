import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:planner/models/task.dart';
import 'package:planner/views/history_page.dart';
import 'package:planner/services/task_service.dart';

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

  testWidgets('shows history entry', (tester) async {
    final service = TaskService();
    final task = Task(title: 'history test', date: DateTime.now(), isCompleted: true);
    await service.addTask(task);

    await tester.pumpWidget(const MaterialApp(home: HistoryPage()));
    await tester.pumpAndSettle();

    expect(find.text('history test'), findsOneWidget);
  });
}
