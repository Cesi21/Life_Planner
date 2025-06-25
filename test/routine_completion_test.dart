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
    await Hive.openBox<Map>('routine_done');
    await Hive.openBox('routine_streaks');
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('routines');
    await Hive.deleteBoxFromDisk('routine_done');
    await Hive.deleteBoxFromDisk('routine_streaks');
  });

  test('completion scoped per date', () async {
    final service = RoutineService();
    final routine =
        Routine(title: 'R', repeatType: RepeatType.daily, weekdays: [1,2,3,4,5,6,7]);
    await service.addRoutine(routine);
    final d1 = DateTime(2020,1,1);
    final d2 = DateTime(2020,1,2);
    await service.markRoutineDone(routine.key.toString(), d1);
    final doneToday = await service.isRoutineDone(routine.key.toString(), d1);
    final doneTomorrow = await service.isRoutineDone(routine.key.toString(), d2);
    expect(doneToday, true);
    expect(doneTomorrow, false);
  });
}
