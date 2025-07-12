import 'package:hive/hive.dart';

part 'mailbox_history.g.dart';

@HiveType(typeId: 3)
class MailboxHistory extends HiveObject {
  @HiveField(0)
  final String email;

  @HiveField(1)
  final String domain;

  @HiveField(2)
  final DateTime lastUsed;

  @HiveField(3)
  final DateTime createdAt;

  MailboxHistory({
    required this.email,
    required this.domain,
    required this.lastUsed,
    required this.createdAt,
  });

  factory MailboxHistory.fromEmailAndDomain(String email, String domain) {
    final now = DateTime.now();
    return MailboxHistory(
      email: email,
      domain: domain,
      lastUsed: now,
      createdAt: now,
    );
  }

  MailboxHistory copyWith({
    String? email,
    String? domain,
    DateTime? lastUsed,
    DateTime? createdAt,
  }) {
    return MailboxHistory(
      email: email ?? this.email,
      domain: domain ?? this.domain,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'domain': domain,
      'lastUsed': lastUsed.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MailboxHistory(email: $email, domain: $domain, lastUsed: $lastUsed)';
  }
}
