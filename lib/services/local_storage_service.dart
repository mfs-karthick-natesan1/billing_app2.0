import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../models/persisted_app_state.dart';

class LocalStorageService {
  static const String _stateFileName = 'billmaster_state_v2.enc';
  static const String _backupFileName = 'billmaster_state_backup_v2.enc';

  // Legacy plain-text filenames for one-time migration
  static const String _legacyStateFile = 'billmaster_state_v1.json';
  static const String _legacyBackupFile = 'billmaster_state_backup_v1.json';

  static const String _keyName = 'billmaster_enc_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> _writeQueue = Future.value();

  Future<String> _getOrCreateKey() async {
    var key = await _secureStorage.read(key: _keyName);
    if (key == null) {
      final rng = Random.secure();
      final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
      key = base64Url.encode(bytes);
      await _secureStorage.write(key: _keyName, value: key);
    }
    return key;
  }

  /// XOR-stream cipher using a 256-bit key stored in secure storage.
  /// Suitable for protecting PII at rest from casual filesystem access.
  String _encrypt(String plainText, String keyBase64) {
    final keyBytes = base64Url.decode(keyBase64);
    final plainBytes = utf8.encode(plainText);
    final encrypted = Uint8List(plainBytes.length);
    for (var i = 0; i < plainBytes.length; i++) {
      encrypted[i] = plainBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return base64.encode(encrypted);
  }

  String _decrypt(String encryptedBase64, String keyBase64) {
    final keyBytes = base64Url.decode(keyBase64);
    final encryptedBytes = base64.decode(encryptedBase64);
    final decrypted = Uint8List(encryptedBytes.length);
    for (var i = 0; i < encryptedBytes.length; i++) {
      decrypted[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return utf8.decode(decrypted);
  }

  Future<PersistedAppState> loadState() async {
    // Try encrypted files first
    final primaryState = await _readEncryptedState(await _stateFile());
    if (primaryState != null) return primaryState;

    final backupState = await _readEncryptedState(await _backupFile());
    if (backupState != null) return backupState;

    // Fall back to legacy plain-text files and migrate to encrypted format
    final legacyState = await _migrateLegacyState();
    return legacyState ?? const PersistedAppState();
  }

  Future<void> saveState(PersistedAppState state) {
    _writeQueue = _writeQueue.then((_) async {
      final key = await _getOrCreateKey();
      final encoded = const JsonEncoder.withIndent('  ').convert(state.toJson());
      final encrypted = _encrypt(encoded, key);
      final stateFile = await _stateFile();
      final backupFile = await _backupFile();
      await stateFile.writeAsString(encrypted, flush: true);
      await backupFile.writeAsString(encrypted, flush: true);
    });
    return _writeQueue;
  }

  Future<void> importStateFromFile(File sourceFile) async {
    final content = await sourceFile.readAsString();
    // Accept plain JSON (human exports) and encrypted files
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } catch (_) {
      try {
        final key = await _getOrCreateKey();
        final plain = _decrypt(content, key);
        decoded = jsonDecode(plain);
      } catch (_) {
        throw const FormatException('Invalid or unreadable state file');
      }
    }
    if (decoded is Map<String, dynamic>) {
      await saveState(PersistedAppState.fromJson(decoded));
      return;
    }
    if (decoded is Map) {
      await saveState(
        PersistedAppState.fromJson(decoded.cast<String, dynamic>()),
      );
      return;
    }
    throw const FormatException('Invalid state file format');
  }

  Future<File> exportStateSnapshot({String? fileName}) async {
    final data = await loadState();
    final dir = await getApplicationDocumentsDirectory();
    final exportName =
        fileName ??
        'billmaster_export_${DateTime.now().millisecondsSinceEpoch}.json';
    final exportFile = File('${dir.path}/$exportName');
    // Export as plain JSON for portability
    await exportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data.toJson()),
      flush: true,
    );
    return exportFile;
  }

  Future<File> _stateFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_stateFileName');
  }

  Future<File> _backupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_backupFileName');
  }

  Future<PersistedAppState?> _readEncryptedState(File file) async {
    try {
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final key = await _getOrCreateKey();
      final plain = _decrypt(content, key);
      final decoded = jsonDecode(plain);
      if (decoded is Map<String, dynamic>) {
        return PersistedAppState.fromJson(decoded);
      }
      if (decoded is Map) {
        return PersistedAppState.fromJson(decoded.cast<String, dynamic>());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<PersistedAppState?> _migrateLegacyState() async {
    final dir = await getApplicationDocumentsDirectory();
    for (final name in [_legacyStateFile, _legacyBackupFile]) {
      final file = File('${dir.path}/$name');
      try {
        if (!await file.exists()) continue;
        final content = await file.readAsString();
        if (content.trim().isEmpty) continue;
        final decoded = jsonDecode(content);
        PersistedAppState? state;
        if (decoded is Map<String, dynamic>) {
          state = PersistedAppState.fromJson(decoded);
        } else if (decoded is Map) {
          state = PersistedAppState.fromJson(decoded.cast<String, dynamic>());
        }
        if (state != null) {
          await saveState(state);
          return state;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }
}
