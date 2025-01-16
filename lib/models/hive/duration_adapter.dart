import 'package:hive_flutter/hive_flutter.dart';

class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final typeId = 0;

  @override
  Duration read(BinaryReader reader) {
    return Duration(milliseconds: reader.readInt());
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMilliseconds);
  }
}
