class TicketComment {
  final String id;
  final String ticketId;
  final String author; // 'support' or 'customer'
  final String message;
  final DateTime createdAt;

  TicketComment({
    required this.id,
    required this.ticketId,
    required this.author,
    required this.message,
    required this.createdAt,
  });

  bool get isSupport => author == 'support';

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      author: json['author'] as String? ?? 'support',
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class SupportTicket {
  final String id;
  final String category;
  final String subject;
  final String description;
  final String? attachmentUrl;
  final String status; // 'open' | 'in_progress' | 'resolved'
  final DateTime createdAt;
  final List<TicketComment> comments;

  SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    this.attachmentUrl,
    required this.status,
    required this.createdAt,
    this.comments = const [],
  });

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';

  String get statusLabel {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      default:
        return 'Open';
    }
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final commentsJson =
        json['support_ticket_comments'] as List<dynamic>? ?? [];
    final comments = commentsJson
        .whereType<Map<String, dynamic>>()
        .map(TicketComment.fromJson)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return SupportTicket(
      id: json['id'] as String,
      category: json['category'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String? ?? '',
      attachmentUrl: json['attachment_url'] as String?,
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
      comments: comments,
    );
  }
}
