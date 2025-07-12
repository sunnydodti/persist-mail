import 'package:hive/hive.dart';

part 'domain_model.g.dart';

@HiveType(typeId: 1)
class DomainModel extends HiveObject {
  @HiveField(0)
  final String domain;

  @HiveField(1)
  final bool isActive;

  @HiveField(2)
  final DateTime? lastUsed;

  DomainModel({required this.domain, this.isActive = true, this.lastUsed});

  factory DomainModel.fromJson(Map<String, dynamic> json) {
    return DomainModel(
      domain: json['domain'] ?? '',
      isActive: json['isActive'] ?? true,
      lastUsed: json['lastUsed'] != null
          ? DateTime.tryParse(json['lastUsed'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'isActive': isActive,
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }
}
