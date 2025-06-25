import '../models/routine.dart';

abstract class IRoutineService {
  Future<List<Routine>> getRoutines();
  Future<List<Routine>> getRoutinesForDay(DateTime day, {String? tagId});
  Future<void> addRoutine(Routine routine);
  Future<void> updateRoutine(Routine routine);
  Future<void> deleteRoutine(Routine routine);
  Future<void> toggleComplete(Routine routine, DateTime day, bool done);
  Future<void> markCompleted(Routine routine, DateTime day, bool done);
  Future<bool> isCompleted(Routine routine, DateTime day);
}
