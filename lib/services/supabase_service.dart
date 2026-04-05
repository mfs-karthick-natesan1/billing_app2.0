import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_config.dart';
import 'https_client_factory.dart';

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

    final httpClient = createHttpsClient(
      allowedHosts: [uri.host, 'supabase.co', 'supabase.in'],
    );

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      httpClient: httpClient,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
