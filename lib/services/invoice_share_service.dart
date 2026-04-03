import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceShareService {
  InvoiceShareService._();

  static Uri buildWhatsappUri({required String text, String? customerPhone}) {
    final phone = _normalizePhone(customerPhone);
    final encodedText = Uri.encodeComponent(text);
    if (phone == null) {
      return Uri.parse('https://wa.me/?text=$encodedText');
    }
    return Uri.parse('https://wa.me/$phone?text=$encodedText');
  }

  static Future<bool> shareOnWhatsApp({
    required String text,
    String? customerPhone,
  }) {
    final uri = buildWhatsappUri(text: text, customerPhone: customerPhone);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> shareText({required String text, String? subject}) {
    return Share.share(text, subject: subject);
  }

  static Future<File> writeTempFile({
    required Uint8List bytes,
    required String fileName,
    required String extension,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$safeName.$extension');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> shareFile({
    required File file,
    String? text,
    String? subject,
  }) {
    return Share.shareXFiles([XFile(file.path)], text: text, subject: subject);
  }

  /// Shares bytes as a file. On web, avoids path_provider (unsupported) by
  /// creating an XFile from raw bytes. On mobile, writes to a temp file first.
  static Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String extension,
    required String mimeType,
    String? text,
    String? subject,
  }) async {
    if (kIsWeb) {
      final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final xFile = XFile.fromData(
        bytes,
        name: '$safeName.$extension',
        mimeType: mimeType,
      );
      await Share.shareXFiles([xFile], text: text, subject: subject);
    } else {
      final file = await writeTempFile(
        bytes: bytes,
        fileName: fileName,
        extension: extension,
      );
      await shareFile(file: file, text: text, subject: subject);
    }
  }

  static String? _normalizePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    if (digits.length == 10) return '91$digits';
    return digits;
  }
}
