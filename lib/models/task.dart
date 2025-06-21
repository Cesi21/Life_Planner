import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  bool isCompleted;

  Task({required this.title, required this.date, this.isCompleted = false});
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
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.title);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.isCompleted);
  }
}
