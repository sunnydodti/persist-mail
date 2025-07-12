// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DomainModelAdapter extends TypeAdapter<DomainModel> {
  @override
  final int typeId = 1;

  @override
  DomainModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DomainModel(
      domain: fields[0] as String,
      isActive: fields[1] as bool,
      lastUsed: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DomainModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.domain)
      ..writeByte(1)
      ..write(obj.isActive)
      ..writeByte(2)
      ..write(obj.lastUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
