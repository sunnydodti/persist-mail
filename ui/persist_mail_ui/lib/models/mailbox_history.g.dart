// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mailbox_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MailboxHistoryAdapter extends TypeAdapter<MailboxHistory> {
  @override
  final int typeId = 3;

  @override
  MailboxHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MailboxHistory(
      email: fields[0] as String,
      domain: fields[1] as String,
      lastUsed: fields[2] as DateTime,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MailboxHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.domain)
      ..writeByte(2)
      ..write(obj.lastUsed)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MailboxHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
