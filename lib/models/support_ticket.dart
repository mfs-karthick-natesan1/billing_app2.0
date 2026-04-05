enum TicketStatus {
  open,
  inProgress,
  resolved;

  String get value {
    switch (this) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.resolved:
        return 'resolved';
    }
  }

  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
    }
  }

  static TicketStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      default:
        return TicketStatus.open;
    }
  }
}

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'ticket_id': ticketId,
    'author': author,
    'message': message,
    'created_at': createdAt.toIso8601String(),
  };
}

class SupportTicket {
  final String id;
  final String category;
  final String subject;
  final String description;
  final String? attachmentUrl;
  final TicketStatus status;
  final DateTime createdAt;
  final List<TicketComment> comments;

  SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    this.attachmentUrl,
    this.status = TicketStatus.open,
    required this.createdAt,
    this.comments = const [],
  });

  bool get isOpen => status == TicketStatus.open;
  bool get isInProgress => status == TicketStatus.inProgress;
  bool get isResolved => status == TicketStatus.resolved;

  String get statusLabel => status.label;

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
      status: TicketStatus.fromString(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      comments: comments,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'subject': subject,
    'description': description,
    if (attachmentUrl != null) 'attachment_url': attachmentUrl,
    'status': status.value,
    'created_at': createdAt.toIso8601String(),
    'support_ticket_comments': comments.map((c) => c.toJson()).toList(),
  };
}
