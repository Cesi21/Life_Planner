import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

enum RepeatType { daily, weekly, custom }

class RepeatTypeAdapter extends TypeAdapter<RepeatType> {
  @override
  final int typeId = 2;

  @override
  RepeatType read(BinaryReader reader) {
    return RepeatType.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, RepeatType obj) {
    writer.writeInt(obj.index);
  }
}

@HiveType(typeId: 1)
class Routine extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  RepeatType repeatType;

  @HiveField(2)
  List<int> weekdays;

  @HiveField(3)
  int? timeMinutes;

  @HiveField(4)
  bool isActive;

  Routine({
    required this.title,
    required this.repeatType,
    required this.weekdays,
    this.timeMinutes,
    this.isActive = true,
  });

  TimeOfDay? get time =>
      timeMinutes == null ? null : TimeOfDay(hour: timeMinutes! ~/ 60, minute: timeMinutes! % 60);
  set time(TimeOfDay? t) => timeMinutes = t == null ? null : t.hour * 60 + t.minute;
}

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 1;

  @override
  Routine read(BinaryReader reader) {
    return Routine(
      title: reader.readString(),
      repeatType: RepeatType.values[reader.readInt()],
      weekdays: List<int>.from(reader.readList()),
      timeMinutes: reader.readBool() ? reader.readInt() : null,
      isActive: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer.writeString(obj.title);
    writer.writeInt(obj.repeatType.index);
    writer.writeList(obj.weekdays);
    if (obj.timeMinutes != null) {
      writer.writeBool(true);
      writer.writeInt(obj.timeMinutes!);
    } else {
      writer.writeBool(false);
    }
    writer.writeBool(obj.isActive);
  }
}
