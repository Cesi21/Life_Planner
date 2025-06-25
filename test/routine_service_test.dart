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
    await Hive.openBox('routineCompletions');
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('routines');
    await Hive.deleteBoxFromDisk('routineCompletions');
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
}
