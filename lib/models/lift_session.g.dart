// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'lift_session.dart';

class LiftSessionAdapter extends TypeAdapter<LiftSession> {
  @override
  final int typeId = 0;

  @override
  LiftSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LiftSession(
      startTime: fields[0] as DateTime,
      liftType: fields[1] as String,
      reps: (fields[2] as List).cast<RepRecord>(),
      endTime: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LiftSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.liftType)
      ..writeByte(2)
      ..write(obj.reps)
      ..writeByte(3)
      ..write(obj.endTime);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiftSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
