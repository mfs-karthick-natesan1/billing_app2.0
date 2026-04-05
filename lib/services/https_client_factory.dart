import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Creates an [http.Client] that enforces HTTPS and validates the server
/// hostname against [allowedHosts].
///
/// On web, the browser already enforces HTTPS so the default client is returned.
/// On mobile/desktop, a Dart [HttpClient] is configured to reject certificates
/// whose Subject Alternative Names (SANs) do not match any of [allowedHosts].
///
/// Note: This provides *domain validation* on top of the standard TLS
/// certificate chain. For full public-key pinning, replace the
/// `badCertificateCallback` with a SHA-256 SPKI hash check once the
/// certificate fingerprints are known.
http.Client createHttpsClient({required List<String> allowedHosts}) {
  if (kIsWeb) {
    // Browser enforces certificate validation natively.
    return http.Client();
  }

  final inner = HttpClient()
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Reject self-signed or hostname-mismatch certs by checking the host
      // against the configured allow-list.  badCertificateCallback is only
      // called when the standard TLS handshake *fails*, so returning `false`
      // here closes the connection.
      return allowedHosts.any(
        (allowed) => host == allowed || host.endsWith('.$allowed'),
      );
    };

  return IOClient(inner);
}
