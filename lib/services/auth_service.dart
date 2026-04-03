import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;

  static User? get currentUser => _client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;

  static String? _businessId;
  static String? get businessId => _businessId;

  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /// Loads the businessId for the currently authenticated user.
  static Future<void> loadBusinessId() async {
    final uid = currentUserId;
    if (uid == null) {
      _businessId = null;
      return;
    }
    final row = await _client
        .from('businesses')
        .select('id')
        .eq('owner_uid', uid)
        .maybeSingle();
    _businessId = row?['id'] as String?;
  }

  static const _timeout = Duration(seconds: 15);

  /// Creates a new Supabase Auth user and a corresponding businesses row.
  static Future<String> signUp({
    required String email,
    required String password,
    required String businessName,
  }) async {
    final res = await _client.auth
        .signUp(email: email, password: password)
        .timeout(_timeout, onTimeout: () => throw Exception('Sign up timed out. Check your connection.'));
    final uid = res.user?.id;
    if (uid == null) throw Exception('Sign up failed — no user returned');

    // If email confirmation is ON, session will be null until confirmed.
    if (res.session == null) {
      throw Exception('Please confirm your email before continuing, or disable email confirmation in Supabase.');
    }

    final row = await _client
        .from('businesses')
        .insert({'owner_uid': uid, 'name': businessName, 'config': {}})
        .select('id')
        .single()
        .timeout(_timeout, onTimeout: () => throw Exception('Connection timed out.'));
    _businessId = row['id'] as String;

    // Create 3-month free trial subscription
    final trialEnd = DateTime.now().add(const Duration(days: 90));
    try {
      await _client.from('subscriptions').insert({
        'business_id': _businessId,
        'tier': 'trial',
        'bills_this_month': 0,
        'trial_ends_at': trialEnd.toIso8601String(),
      }).timeout(_timeout);
    } catch (_) {
      // Non-fatal: subscription row can be created later on first load
    }

    return _businessId!;
  }

  /// Signs in with email + password and loads the businessId.
  static Future<String> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth
        .signInWithPassword(email: email, password: password)
        .timeout(_timeout, onTimeout: () => throw Exception('Sign in timed out. Check your connection.'));
    await loadBusinessId();
    if (_businessId == null) throw Exception('Business record not found');
    return _businessId!;
  }

  static Future<void> signOut() async {
    _businessId = null;
    await _client.auth.signOut();
  }

  /// Submits a support ticket (with optional screenshot bytes) to Supabase.
  static Future<void> submitSupportTicket({
    required String category,
    required String subject,
    required String description,
    List<int>? screenshotBytes,
    String? fileName,
  }) async {
    if (_businessId == null) throw Exception('Not signed in');

    String? attachmentUrl;

    // Upload screenshot to Supabase Storage if provided
    if (screenshotBytes != null && screenshotBytes.isNotEmpty) {
      final ext = (fileName ?? 'screenshot.png').split('.').last;
      final path = '$_businessId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage
          .from('support-attachments')
          .uploadBinary(path, Uint8List.fromList(screenshotBytes))
          .timeout(_timeout);
      attachmentUrl = _client.storage
          .from('support-attachments')
          .getPublicUrl(path);
    }

    await _client.from('support_tickets').insert({
      'business_id': _businessId,
      'email': currentUser?.email,
      'category': category,
      'subject': subject,
      'description': description,
      'attachment_url': attachmentUrl,
      'status': 'open',
    }).timeout(_timeout);
  }

  /// Fetches tickets for this business:
  /// - Open / in_progress tickets: always shown
  /// - Resolved tickets: only last 3 months
  static Future<List<Map<String, dynamic>>> fetchSupportTickets() async {
    if (_businessId == null) return [];
    final rows = await _client
        .from('support_tickets')
        .select('*, support_ticket_comments(*)')
        .eq('business_id', _businessId!)
        .order('created_at', ascending: false)
        .timeout(_timeout);

    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
    return (rows as List).where((t) {
      final status = t['status'] as String? ?? 'open';
      if (status != 'resolved') return true;
      final createdAt = DateTime.tryParse(t['created_at'] as String? ?? '');
      return createdAt != null && createdAt.isAfter(threeMonthsAgo);
    }).cast<Map<String, dynamic>>().toList();
  }

  /// Adds a customer reply comment to a ticket.
  static Future<void> addTicketComment({
    required String ticketId,
    required String message,
  }) async {
    await _client.from('support_ticket_comments').insert({
      'ticket_id': ticketId,
      'author': 'customer',
      'message': message,
    }).timeout(_timeout);
  }

  /// Updates the current user's password.
  static Future<void> changePassword({
    required String newPassword,
  }) async {
    await _client.auth
        .updateUser(UserAttributes(password: newPassword))
        .timeout(_timeout, onTimeout: () => throw Exception('Request timed out.'));
  }
}
