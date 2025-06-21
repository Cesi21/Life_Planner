import 'package:hive/hive.dart';


@HiveType(typeId: 0)
class Routine extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  bool isCompleted;

  Routine({required this.title, required this.date, this.isCompleted = false});
}

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 0;

  @override
  Routine read(BinaryReader reader) {
    return Routine(
      title: reader.readString(),
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isCompleted: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer.writeString(obj.title);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.isCompleted);
  }
}
