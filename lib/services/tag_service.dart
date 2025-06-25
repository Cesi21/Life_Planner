import 'package:hive_flutter/hive_flutter.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../models/routine.dart';
import 'task_service.dart';
import 'routine_service.dart';

class TagService {
  static const String boxName = 'tags';

  Future<Box<Tag>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<Tag>(boxName);
    return await Hive.openBox<Tag>(boxName);
  }

  Future<List<Tag>> getAllTags() async {
    final box = await _openBox();
    return box.values.toList();
  }

  Tag? getTagById(String id) {
    final key = int.tryParse(id);
    if (key == null) return null;
    if (!Hive.isBoxOpen(boxName)) return null;
    return Hive.box<Tag>(boxName).get(key);
  }

  Future<bool> addTag(Tag tag) async {
    final box = await _openBox();
    if (box.values.any((t) => t.name.toLowerCase() == tag.name.toLowerCase())) {
      return false;
    }
    await box.add(tag);
    return true;
  }

  Future<bool> updateTag(Tag tag) async {
    final box = await _openBox();
    if (box.values.any((t) => t.key != tag.key &&
        t.name.toLowerCase() == tag.name.toLowerCase())) {
      return false;
    }
    await tag.save();
    return true;
  }

  Future<void> deleteTag(Tag tag) async {
    final id = tag.key.toString();
    await tag.delete();
    await _cascadeDelete(id);
  }

  Future<void> _cascadeDelete(String tagId) async {
    final taskBox = await Hive.openBox<Task>(TaskService.boxName);
    for (final t in taskBox.values) {
      if (t.tagId == tagId) {
        t.tagId = null;
        await t.save();
      }
    }

    final routineBox = await Hive.openBox<Routine>(RoutineService.boxName);
    for (final r in routineBox.values) {
      if (r.tagId == tagId) {
        r.tagId = null;
        await r.save();
      }
    }
  }
}
