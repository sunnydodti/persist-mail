import 'package:hive/hive.dart';

part 'email_model.g.dart';

@HiveType(typeId: 0)
class EmailModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String from;

  @HiveField(2)
  final String to;

  @HiveField(3)
  final String subject;

  @HiveField(4)
  final String body;

  @HiveField(5)
  final DateTime receivedAt;

  @HiveField(6)
  final bool isRead;

  @HiveField(7)
  final String? htmlBody;

  EmailModel({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    this.htmlBody,
  });

  factory EmailModel.fromJson(
    Map<String, dynamic> json, [
    String? emailAddress,
  ]) {
    return EmailModel(
      id: json['id']?.toString() ?? '',
      from: json['sender'] ?? json['from'] ?? '',
      to: emailAddress ?? json['to'] ?? '',
      subject: json['subject'] ?? '',
      body: json['snippet'] ?? json['body'] ?? '',
      receivedAt:
          DateTime.tryParse(
            json['received_date'] ?? json['receivedAt'] ?? '',
          ) ??
          DateTime.now(),
      isRead: json['isRead'] ?? false,
      htmlBody: json['htmlBody'] ?? json['html_body'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'subject': subject,
      'body': body,
      'receivedAt': receivedAt.toIso8601String(),
      'isRead': isRead,
      'htmlBody': htmlBody,
    };
  }

  EmailModel copyWith({
    String? id,
    String? from,
    String? to,
    String? subject,
    String? body,
    DateTime? receivedAt,
    bool? isRead,
    String? htmlBody,
  }) {
    return EmailModel(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      htmlBody: htmlBody ?? this.htmlBody,
    );
  }
}
