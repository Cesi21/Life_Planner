import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class Tag extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  int colorValue;

  Color get color => Color(colorValue);
  set color(Color c) => colorValue = c.value;

  Tag({required this.name, required Color color}) : colorValue = color.value;
}

class TagAdapter extends TypeAdapter<Tag> {
  @override
  final int typeId = 3;

  @override
  Tag read(BinaryReader reader) {
    return Tag(
      name: reader.readString(),
      color: Color(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Tag obj) {
    writer.writeString(obj.name);
    writer.writeInt(obj.colorValue);
  }
}
