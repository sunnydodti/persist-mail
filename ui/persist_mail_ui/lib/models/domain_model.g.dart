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
      id: fields[0] as int,
      domain: fields[1] as String,
      isActive: fields[2] as bool,
      isPremium: fields[3] as bool,
      isMailcowManaged: fields[4] as bool,
      createdAt: fields[5] as DateTime,
      lastUsed: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DomainModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.domain)
      ..writeByte(2)
      ..write(obj.isActive)
      ..writeByte(3)
      ..write(obj.isPremium)
      ..writeByte(4)
      ..write(obj.isMailcowManaged)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
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
