import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:planner/models/routine.dart';
import 'package:planner/services/routine_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Hive.initFlutter();
    Hive.registerAdapter(RepeatTypeAdapter());
    Hive.registerAdapter(RoutineAdapter());
    await Hive.openBox<Routine>('routines');
    await Hive.openBox<List>('routine_done');
    await Hive.openBox('routine_streaks');
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('routines');
    await Hive.deleteBoxFromDisk('routine_done');
    await Hive.deleteBoxFromDisk('routine_streaks');
  });

  test('mark routine completed', () async {
    final service = RoutineService();
    final routine = Routine(title: 'R', repeatType: RepeatType.daily, weekdays: [1,2,3,4,5,6,7]);
    await service.addRoutine(routine);
    final date = DateTime(2020);
    await service.markCompleted(routine, date, true);
    final completed = await service.isCompleted(routine, date);
    expect(completed, true);
  });

  test('streak increment', () async {
    final service = RoutineService();
    final routine = Routine(title: 'S', repeatType: RepeatType.daily, weekdays: [1,2,3,4,5,6,7]);
    await service.addRoutine(routine);
    final d1 = DateTime(2020,1,1);
    final d2 = DateTime(2020,1,2);
    await service.markCompleted(routine, d1, true);
    await service.markCompleted(routine, d2, true);
    final streak = await service.getCurrentStreak(routine.key.toString());
    expect(streak, 2);
  });
}
