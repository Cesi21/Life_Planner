import 'dart:convert';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';
import '../models/routine.dart';
import '../models/tag.dart';

class BackupService {
  BackupService._();
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;

  Future<String> _filePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/planner_backup.json';
  }

  Future<String> exportAll() async {
    final taskBox = Hive.box<Task>('tasks');
    final routineBox = Hive.box<Routine>('routines');
    final tagBox = Hive.box<Tag>('tags');
    final streakBox = Hive.box('routine_streaks');
    final data = {
      'tasks': taskBox.values.map((t) => {
        'title': t.title,
        'date': t.date.toIso8601String(),
        'isCompleted': t.isCompleted,
        'tagId': t.tagId,
        'reminderMinutes': t.reminderMinutes,
      }).toList(),
      'routines': routineBox.values.map((r) => {
        'title': r.title,
        'repeatType': r.repeatType.index,
        'weekdays': r.weekdays,
        'timeMinutes': r.timeMinutes,
        'isActive': r.isActive,
        'durationMinutes': r.durationMinutes,
        'tagId': r.tagId,
      }).toList(),
      'tags': tagBox.values.map((t) => {
        'name': t.name,
        'colorValue': t.colorValue,
      }).toList(),
      'streaks': streakBox.toMap(),
    };
    final jsonStr = jsonEncode(data);
    if (kIsWeb) {
      final encoded = base64Encode(utf8.encode(jsonStr));
      final now = DateTime.now();
      final name =
          'backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';
      final anchor = html.AnchorElement(
          href: 'data:application/json;base64,$encoded')
        ..download = name
        ..target = 'blank';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      return name;
    } else {
      final file = File(await _filePath());
      await file.writeAsString(jsonStr);
      return file.path;
    }
  }

  Future<void> importAll(dynamic fileOrBytes) async {
    String content;
    if (kIsWeb) {
      if (fileOrBytes is Uint8List) {
        content = utf8.decode(fileOrBytes);
      } else {
        return;
      }
    } else {
      final file = fileOrBytes as File;
      content = await file.readAsString();
    }
    final data = jsonDecode(content);
    final taskBox = Hive.box<Task>('tasks');
    final routineBox = Hive.box<Routine>('routines');
    final tagBox = Hive.box<Tag>('tags');
    final streakBox = Hive.box('routine_streaks');
    await taskBox.clear();
    await routineBox.clear();
    await tagBox.clear();
    await streakBox.clear();
    for (final t in data['tasks']) {
      await taskBox.add(Task(
        title: t['title'],
        date: DateTime.parse(t['date']),
        isCompleted: t['isCompleted'],
        tagId: t['tagId'],
        reminderMinutes: t['reminderMinutes'],
      ));
    }
    for (final r in data['routines']) {
      await routineBox.add(Routine(
        title: r['title'],
        repeatType: RepeatType.values[r['repeatType']],
        weekdays: List<int>.from(r['weekdays']),
        timeMinutes: r['timeMinutes'],
        isActive: r['isActive'],
        durationMinutes: r['durationMinutes'],
        tagId: r['tagId'],
      ));
    }
    for (final t in data['tags']) {
      await tagBox.add(Tag(name: t['name'], color: Color(t['colorValue'])));
    }
    final streaks = Map<String, dynamic>.from(data['streaks'] ?? {});
    for (final key in streaks.keys) {
      await streakBox.put(key, streaks[key]);
    }
  }
}
