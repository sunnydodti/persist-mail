import 'package:hive/hive.dart';

part 'domain_model.g.dart';

@HiveType(typeId: 1)
class DomainModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String domain;

  @HiveField(2)
  final bool isActive;

  @HiveField(3)
  final bool isPremium;

  @HiveField(4)
  final bool isMailcowManaged;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime? lastUsed;

  DomainModel({
    required this.id,
    required this.domain,
    this.isActive = true,
    this.isPremium = false,
    this.isMailcowManaged = false,
    required this.createdAt,
    this.lastUsed,
  });

  factory DomainModel.fromJson(Map<String, dynamic> json) {
    return DomainModel(
      id: json['id'] ?? 0,
      domain: json['domain'] ?? '',
      isActive: json['is_active'] ?? true,
      isPremium: json['is_premium'] ?? false,
      isMailcowManaged: json['is_mailcow_managed'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      lastUsed: json['last_used'] != null
          ? DateTime.tryParse(json['last_used'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'is_active': isActive,
      'is_premium': isPremium,
      'is_mailcow_managed': isMailcowManaged,
      'created_at': createdAt.toIso8601String(),
      'last_used': lastUsed?.toIso8601String(),
    };
  }
}
