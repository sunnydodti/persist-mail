// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserPreferencesAdapter extends TypeAdapter<UserPreferences> {
  @override
  final int typeId = 2;

  @override
  UserPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserPreferences(
      isDarkMode: fields[0] as bool,
      refreshInterval: fields[1] as int,
      selectedEmail: fields[2] as String?,
      selectedDomain: fields[3] as String?,
      autoRefreshEnabled: fields[4] as bool,
      lastAppOpen: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserPreferences obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.refreshInterval)
      ..writeByte(2)
      ..write(obj.selectedEmail)
      ..writeByte(3)
      ..write(obj.selectedDomain)
      ..writeByte(4)
      ..write(obj.autoRefreshEnabled)
      ..writeByte(5)
      ..write(obj.lastAppOpen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferencesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
