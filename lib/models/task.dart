import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  String? tag;

  @HiveField(4)
  int? reminderMinutes;

  @HiveField(5)
  String? tagId;

  TimeOfDay? get reminderTime => reminderMinutes == null
      ? null
      : TimeOfDay(hour: reminderMinutes! ~/ 60, minute: reminderMinutes! % 60);
  set reminderTime(TimeOfDay? t) =>
      reminderMinutes = t == null ? null : t.hour * 60 + t.minute;

  Task({
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.tag,
    this.reminderMinutes,
    this.tagId,
  });
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    return Task(
      title: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isCompleted: reader.readBool(),
      tag: reader.readBool() ? reader.readString() : null,
      reminderMinutes: reader.readBool() ? reader.readInt() : null,
      tagId: reader.readBool() ? reader.readString() : null,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.title);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.isCompleted);
    if (obj.tag != null) {
      writer.writeBool(true);
      writer.writeString(obj.tag!);
    } else {
      writer.writeBool(false);
    }
    if (obj.reminderMinutes != null) {
      writer.writeBool(true);
      writer.writeInt(obj.reminderMinutes!);
    } else {
      writer.writeBool(false);
    }
    if (obj.tagId != null) {
      writer.writeBool(true);
      writer.writeString(obj.tagId!);
    } else {
      writer.writeBool(false);
    }
  }
}
