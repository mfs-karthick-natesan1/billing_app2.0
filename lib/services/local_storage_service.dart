import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/persisted_app_state.dart';

class LocalStorageService {
  static const String _stateFileName = 'billmaster_state_v1.json';
  static const String _backupFileName = 'billmaster_state_backup_v1.json';

  Future<void> _writeQueue = Future.value();

  Future<PersistedAppState> loadState() async {
    final primaryState = await _readStateFromFile(await _stateFile());
    if (primaryState != null) {
      return primaryState;
    }
    final backupState = await _readStateFromFile(await _backupFile());
    return backupState ?? const PersistedAppState();
  }

  Future<void> saveState(PersistedAppState state) {
    _writeQueue = _writeQueue.then((_) async {
      final file = await _stateFile();
      final backupFile = await _backupFile();
      final encoded = const JsonEncoder.withIndent(
        '  ',
      ).convert(state.toJson());
      await file.writeAsString(encoded, flush: true);
      await backupFile.writeAsString(encoded, flush: true);
    });
    return _writeQueue;
  }

  Future<void> importStateFromFile(File sourceFile) async {
    final content = await sourceFile.readAsString();
    final decoded = jsonDecode(content);
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

  Future<PersistedAppState?> _readStateFromFile(File file) async {
    try {
      if (!await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;

      final decoded = jsonDecode(content);
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
}
