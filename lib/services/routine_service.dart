import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine.dart';

class RoutineService {
  static const String boxName = 'routines';

  Future<Box<Routine>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Routine>(boxName);
    }
    return await Hive.openBox<Routine>(boxName);
  }

  Future<List<Routine>> getRoutines() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Future<void> addRoutine(Routine routine) async {
    final box = await _openBox();
    await box.add(routine);
  }

  Future<void> updateRoutine(Routine routine) async {
    await routine.save();
  }

  Future<void> deleteRoutine(Routine routine) async {
    await routine.delete();
  }
}
