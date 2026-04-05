import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';

class SupabaseService {
  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Supabase credentials not configured. '
        'Pass --dart-define=SUPABASE_URL=... and '
        '--dart-define=SUPABASE_ANON_KEY=... when building.',
      );
    }

    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null || uri.scheme != 'https') {
      throw StateError(
        'SUPABASE_URL must use HTTPS. Received: $supabaseUrl',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
