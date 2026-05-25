// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'rep_record.dart';

class RepRecordAdapter extends TypeAdapter<RepRecord> {
  @override
  final int typeId = 1;

  @override
  RepRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RepRecord(
      timestamp: fields[0] as DateTime,
      isValid: fields[1] as bool,
      formScore: fields[2] as double,
      minDepthAngle: fields[3] as double,
      lockoutAngle: fields[4] as double,
      faultNotes: (fields[5] as List).cast<String>(),
      durationSeconds: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, RepRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.isValid)
      ..writeByte(2)
      ..write(obj.formScore)
      ..writeByte(3)
      ..write(obj.minDepthAngle)
      ..writeByte(4)
      ..write(obj.lockoutAngle)
      ..writeByte(5)
      ..write(obj.faultNotes)
      ..writeByte(6)
      ..write(obj.durationSeconds);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
