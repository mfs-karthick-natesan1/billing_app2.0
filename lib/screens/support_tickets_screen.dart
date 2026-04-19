import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/support_ticket.dart';
import '../services/auth_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  List<SupportTicket> _tickets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await AuthService.fetchSupportTickets();
      final tickets = rows.map(SupportTicket.fromJson).toList();
      if (mounted) setState(() => _tickets = tickets);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = _tickets.where((t) => !t.isResolved).toList();
    final resolved = _tickets.where((t) => t.isResolved).toList();

    return Scaffold(
      appBar: AppTopBar(
        title: 'Support Tickets',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text('Failed to load tickets',
                          style: AppTypography.body),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.support_agent_outlined,
                              size: 56,
                              color: AppColors.muted.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No support tickets yet',
                              style: AppTypography.body
                                  .copyWith(color: AppColors.muted)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        children: [
                          if (open.isNotEmpty) ...[
                            _sectionHeader('Open Tickets', open.length),
                            const SizedBox(height: AppSpacing.small),
                            ...open.map((t) => _TicketCard(
                                  ticket: t,
                                  onRefresh: _load,
                                )),
                            const SizedBox(height: AppSpacing.large),
                          ],
                          if (resolved.isNotEmpty) ...[
                            _sectionHeader(
                                'Resolved (Last 3 Months)', resolved.length),
                            const SizedBox(height: AppSpacing.small),
                            ...resolved.map((t) => _TicketCard(
                                  ticket: t,
                                  onRefresh: _load,
                                )),
                          ],
                          if (open.isEmpty && resolved.isEmpty)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.large),
                                child: Text('No tickets found',
                                    style: AppTypography.label),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count',
              style: AppTypography.label.copyWith(color: AppColors.primary)),
        ),
      ],
    );
  }
}

// ─── Ticket Card ──────────────────────────────────────────────────────────────

class _TicketCard extends StatefulWidget {
  final SupportTicket ticket;
  final VoidCallback onRefresh;

  const _TicketCard({required this.ticket, required this.onRefresh});

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _expanded = false;
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Color get _statusColor {
    if (widget.ticket.isInProgress) return const Color(0xFF2563EB); // blue
    if (widget.ticket.isResolved) return AppColors.success;
    return AppColors.warning; // open = orange
  }

  Color get _statusBg {
    if (widget.ticket.isInProgress)
      return const Color(0xFF2563EB).withValues(alpha: 0.10);
    if (widget.ticket.isResolved) return AppColors.success.withValues(alpha: 0.10);
    return AppColors.warning.withValues(alpha: 0.10);
  }

  Future<void> _sendReply() async {
    final msg = _replyCtrl.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    try {
      await AuthService.addTicketComment(
        ticketId: widget.ticket.id,
        message: msg,
      );
      _replyCtrl.clear();
      widget.onRefresh();
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Failed to send: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.mutedLight(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.category,
                                style: AppTypography.label.copyWith(
                                    fontSize: 10, color: AppColors.muted),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Status chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                t.statusLabel,
                                style: AppTypography.label.copyWith(
                                    fontSize: 11, color: _statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(t.subject,
                            style: AppTypography.body
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              Formatters.date(t.createdAt),
                              style: AppTypography.label
                                  .copyWith(color: AppColors.muted),
                            ),
                            if (t.comments.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.chat_bubble_outline,
                                  size: 13, color: AppColors.muted),
                              const SizedBox(width: 3),
                              Text(
                                '${t.comments.length}',
                                style: AppTypography.label
                                    .copyWith(color: AppColors.muted),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail ──────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text('Description',
                      style: AppTypography.label.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 4),
                  Text(t.description, style: AppTypography.body.copyWith(fontSize: 14)),

                  // Comments thread
                  if (t.comments.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.medium),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.small),
                    Text('Conversation',
                        style: AppTypography.label.copyWith(color: AppColors.muted)),
                    const SizedBox(height: AppSpacing.small),
                    ...t.comments.map((c) => _CommentBubble(comment: c)),
                  ],

                  // Reply box (only for open/in-progress)
                  if (!t.isResolved) ...[
                    const SizedBox(height: AppSpacing.small),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyCtrl,
                            maxLines: 3,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: AppTypography.label
                                  .copyWith(color: AppColors.muted),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.cardRadius),
                                borderSide: BorderSide(
                                    color:
                                        AppColors.muted.withValues(alpha: 0.3)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _sending
                            ? const SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                onPressed: _sendReply,
                                icon: const Icon(Icons.send),
                                color: AppColors.primary,
                                tooltip: 'Send',
                              ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Comment Bubble ───────────────────────────────────────────────────────────

class _CommentBubble extends StatelessWidget {
  final TicketComment comment;

  const _CommentBubble({required this.comment});

  @override
  Widget build(BuildContext context) {
    final isSupport = comment.isSupport;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isSupport ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isSupport) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight(0.15),
              child: const Icon(Icons.support_agent,
                  size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isSupport
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSupport
                        ? AppColors.primaryLight(0.08)
                        : AppColors.muted.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isSupport
                          ? Radius.zero
                          : const Radius.circular(12),
                      bottomRight: isSupport
                          ? const Radius.circular(12)
                          : Radius.zero,
                    ),
                    border: isSupport
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2))
                        : null,
                  ),
                  child: Text(
                    comment.message,
                    style: AppTypography.body.copyWith(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSupport)
                      Text('Support Team  · ',
                          style: AppTypography.label.copyWith(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    Text(
                      Formatters.time(comment.createdAt),
                      style: AppTypography.label
                          .copyWith(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isSupport) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.muted.withValues(alpha: 0.15),
              child: Icon(Icons.person, size: 16, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
