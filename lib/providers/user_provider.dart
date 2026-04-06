import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/user_role.dart';
import '../services/permission_service.dart';

class UserProvider extends ChangeNotifier {
  static const int defaultAutoLockMinutes = 5;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 5);

  final List<AppUser> _users = [];
  final VoidCallback? _onChanged;

  /// Tracks consecutive failed PIN attempts per user-id (or phone).
  final Map<String, int> _failedAttempts = {};

  /// Timestamp when the lockout expires per user-id (or phone).
  final Map<String, DateTime> _lockoutUntil = {};

  AppUser? _currentUser;
  bool _isLocked;
  bool _singleUserMode;
  bool _requirePinOnOpen;
  int _autoLockMinutes;

  UserProvider({
    List<AppUser>? initialUsers,
    String? initialCurrentUserId,
    bool singleUserMode = true,
    bool isLocked = false,
    bool requirePinOnOpen = true,
    int autoLockMinutes = defaultAutoLockMinutes,
    VoidCallback? onChanged,
  }) : _onChanged = onChanged,
       _isLocked = isLocked,
       _singleUserMode = singleUserMode,
       _requirePinOnOpen = requirePinOnOpen,
       _autoLockMinutes = autoLockMinutes {
    if (initialUsers != null) {
      _users.addAll(initialUsers);
    }

    if (_users.isNotEmpty) {
      _singleUserMode = false;
    }

    if (initialCurrentUserId != null && _users.isNotEmpty) {
      final active = _users.where((user) => user.isActive).toList();
      if (active.isNotEmpty) {
        _currentUser = active.firstWhere(
          (user) => user.id == initialCurrentUserId,
          orElse: () => active.first,
        );
      }
    }
  }

  List<AppUser> get activeUsers =>
      _users.where((user) => user.isActive).toList(growable: false);

  List<AppUser> get allUsers => List.unmodifiable(_users);

  AppUser? get currentUser => _currentUser;

  UserRole? get currentRole => _currentUser?.role;

  bool get isOwner => _singleUserMode || _currentUser?.role == UserRole.owner;

  bool get isLoggedIn => _singleUserMode || _currentUser != null;

  bool get isLocked => _isLocked;

  bool get singleUserMode => _singleUserMode;

  bool get requirePinOnOpen => _requirePinOnOpen;

  int get autoLockMinutes => _autoLockMinutes;

  bool get hasUsers => _users.isNotEmpty;

  bool get shouldShowLoginScreen {
    if (_singleUserMode) return false;
    if (_isLocked) return true;
    if (_requirePinOnOpen) return true;
    return _currentUser == null;
  }

  String? get currentUserId => _currentUser?.id;

  bool canPerform(Permission action) {
    if (_singleUserMode) return true;
    final role = _currentUser?.role;
    if (role == null) return false;
    return PermissionService.canPerform(role, action);
  }

  bool hasAccessTo(AppSection section) {
    if (_singleUserMode) return true;
    final role = _currentUser?.role;
    if (role == null) return false;
    return PermissionService.hasAccessTo(role, section);
  }

  bool phoneExists(String phone, {String? excludeUserId}) {
    final normalized = _normalizePhone(phone);
    return _users.any(
      (user) =>
          user.id != excludeUserId && _normalizePhone(user.phone) == normalized,
    );
  }

  bool createOwnerAndEnableManagement({
    required String name,
    required String phone,
    required String pin,
  }) {
    final normalizedPhone = _normalizePhone(phone);
    if (name.trim().isEmpty ||
        normalizedPhone.length != 10 ||
        !_isValidPin(pin)) {
      return false;
    }
    if (_users.isNotEmpty || phoneExists(phone)) {
      return false;
    }

    final owner = AppUser(
      name: name.trim(),
      phone: normalizedPhone,
      pinHash: hashPin(pin, phone: normalizedPhone),
      role: UserRole.owner,
      avatarColor: _colorForSeed(normalizedPhone),
    );

    _users.add(owner);
    _currentUser = owner;
    _singleUserMode = false;
    _isLocked = false;
    _persistAndNotify();
    return true;
  }

  bool addUser({
    required String name,
    required String phone,
    required String pin,
    required UserRole role,
  }) {
    if (!_singleUserMode && !canPerform(Permission.manageUsers)) {
      return false;
    }
    final normalizedPhone = _normalizePhone(phone);
    if (name.trim().isEmpty ||
        normalizedPhone.length != 10 ||
        !_isValidPin(pin)) {
      return false;
    }
    if (phoneExists(normalizedPhone)) {
      return false;
    }
    if (role == UserRole.owner) {
      return false;
    }

    final user = AppUser(
      name: name.trim(),
      phone: normalizedPhone,
      pinHash: hashPin(pin, phone: normalizedPhone),
      role: role,
      createdBy: _currentUser?.id,
      avatarColor: _colorForSeed(normalizedPhone),
    );
    _users.add(user);
    _persistAndNotify();
    return true;
  }

  bool updateUser(AppUser updated) {
    if (!_singleUserMode && !canPerform(Permission.manageUsers)) {
      return false;
    }

    final index = _users.indexWhere((user) => user.id == updated.id);
    if (index == -1) return false;

    if (phoneExists(updated.phone, excludeUserId: updated.id)) {
      return false;
    }

    final existing = _users[index];
    final resolvedRole = existing.role == UserRole.owner
        ? UserRole.owner
        : updated.role;
    final resolvedActive = existing.role == UserRole.owner
        ? true
        : updated.isActive;

    _users[index] = existing.copyWith(
      name: updated.name.trim(),
      phone: _normalizePhone(updated.phone),
      role: resolvedRole,
      isActive: resolvedActive,
      avatarColor: updated.avatarColor,
    );

    if (_currentUser?.id == updated.id) {
      _currentUser = _users[index];
    }

    _persistAndNotify();
    return true;
  }

  bool deactivateUser(String id) {
    if (!_singleUserMode && !canPerform(Permission.manageUsers)) {
      return false;
    }

    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) return false;
    if (_users[index].role == UserRole.owner) return false;

    _users[index] = _users[index].copyWith(isActive: false);
    if (_currentUser?.id == id) {
      _currentUser = null;
      _isLocked = false;
    }
    _persistAndNotify();
    return true;
  }

  bool reactivateUser(String id) {
    if (!_singleUserMode && !canPerform(Permission.manageUsers)) {
      return false;
    }

    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) return false;
    _users[index] = _users[index].copyWith(isActive: true);
    _persistAndNotify();
    return true;
  }

  bool resetUserPin(String userId, String newPin) {
    if (!_singleUserMode && !canPerform(Permission.manageUsers)) {
      return false;
    }
    if (!_isValidPin(newPin)) return false;

    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) return false;

    final existing = _users[index];
    _users[index] = existing.copyWith(
      pinHash: hashPin(newPin, phone: existing.phone),
    );
    _persistAndNotify();
    return true;
  }

  bool login(String phone, String pin) {
    if (_singleUserMode) return true;

    final normalizedPhone = _normalizePhone(phone);
    final userMatches = _users.where(
      (user) => user.isActive && _normalizePhone(user.phone) == normalizedPhone,
    );
    if (userMatches.isEmpty) return false;
    return loginByUserId(userMatches.first.id, pin);
  }

  /// Returns the number of remaining login attempts for [key], or 0 if locked.
  int remainingAttempts(String key) {
    if (_isLockedOut(key)) return 0;
    return _maxFailedAttempts - (_failedAttempts[key] ?? 0);
  }

  /// Whether [key] (user-id) is currently locked out due to too many failures.
  bool isAccountLockedOut(String key) => _isLockedOut(key);

  bool loginByUserId(String userId, String pin) {
    if (_singleUserMode) return true;

    if (_isLockedOut(userId)) return false;

    final index = _users.indexWhere(
      (user) => user.id == userId && user.isActive,
    );
    if (index == -1) return false;

    final user = _users[index];
    if (!verifyPin(pin, user.pinHash, phone: user.phone)) {
      _recordFailedAttempt(userId);
      return false;
    }

    _clearFailedAttempts(userId);
    var updated = user.copyWith(lastLoginAt: DateTime.now());
    // Upgrade legacy sha256 hashes to pbkdf2 opportunistically on login.
    if (!user.pinHash.startsWith(_pbkdf2Prefix)) {
      updated = updated.copyWith(pinHash: hashPin(pin, phone: user.phone));
    }
    _users[index] = updated;
    _currentUser = updated;
    _isLocked = false;
    _persistAndNotify();
    return true;
  }

  bool switchUser(String userId, String pin) {
    return loginByUserId(userId, pin);
  }

  void logout() {
    _currentUser = null;
    _isLocked = false;
    _persistAndNotify();
  }

  void lockApp() {
    if (_singleUserMode || _currentUser == null) return;
    _isLocked = true;
    notifyListeners();
  }

  bool unlockApp(String pin) {
    if (_singleUserMode) return true;
    final user = _currentUser;
    if (user == null) return false;

    if (_isLockedOut(user.id)) return false;

    if (!verifyPin(pin, user.pinHash, phone: user.phone)) {
      _recordFailedAttempt(user.id);
      return false;
    }
    _clearFailedAttempts(user.id);
    // Upgrade legacy sha256 hashes to pbkdf2 on successful unlock.
    if (!user.pinHash.startsWith(_pbkdf2Prefix)) {
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        final upgraded = _users[index].copyWith(
          pinHash: hashPin(pin, phone: user.phone),
        );
        _users[index] = upgraded;
        _currentUser = upgraded;
      }
    }
    _isLocked = false;
    notifyListeners();
    return true;
  }

  void updateSecuritySettings({
    required bool requirePinOnOpen,
    required int autoLockMinutes,
  }) {
    _requirePinOnOpen = requirePinOnOpen;
    _autoLockMinutes = autoLockMinutes;
    _persistAndNotify();
  }

  // PBKDF2-HMAC-SHA256 parameters. 100k iterations is OWASP's minimum for
  // SHA-256 and runs in well under 100ms on a phone, which is acceptable for a
  // PIN login. Salt is 16 random bytes sourced from Random.secure().
  static const String _pbkdf2Prefix = 'pbkdf2\$';
  static const int _pbkdf2Iterations = 100000;
  static const int _pbkdf2SaltBytes = 16;
  static const int _pbkdf2KeyBytes = 32;
  static final Random _secureRandom = Random.secure();

  /// Hashes [pin] using PBKDF2-HMAC-SHA256 with a fresh random salt.
  ///
  /// [phone] is accepted for backward-compatibility with older call sites
  /// but is no longer mixed into the hash — the random per-user salt makes
  /// rainbow-table attacks infeasible without it.
  static String hashPin(String pin, {required String phone}) {
    final salt = Uint8List(_pbkdf2SaltBytes);
    for (var i = 0; i < salt.length; i++) {
      salt[i] = _secureRandom.nextInt(256);
    }
    final derived = _pbkdf2(utf8.encode(pin), salt, _pbkdf2Iterations,
        _pbkdf2KeyBytes);
    return '$_pbkdf2Prefix$_pbkdf2Iterations\$${base64.encode(salt)}\$'
        '${base64.encode(derived)}';
  }

  /// Verifies [pin] against a [storedHash]. Accepts both the new PBKDF2
  /// format and the legacy sha256(phone|pin|billmaster) format so existing
  /// user records keep working until they re-login (at which point callers
  /// should upgrade the stored hash).
  static bool verifyPin(String pin, String storedHash,
      {required String phone}) {
    if (storedHash.startsWith(_pbkdf2Prefix)) {
      final parts = storedHash.split(r'$');
      // ['pbkdf2', iters, salt, hash]
      if (parts.length != 4) return false;
      final iters = int.tryParse(parts[1]);
      if (iters == null || iters <= 0) return false;
      final Uint8List salt;
      final Uint8List expected;
      try {
        salt = base64.decode(parts[2]);
        expected = base64.decode(parts[3]);
      } catch (_) {
        return false;
      }
      final derived = _pbkdf2(utf8.encode(pin), salt, iters, expected.length);
      return _constantTimeEquals(derived, expected);
    }
    // Legacy sha256(phone|pin|billmaster) format.
    final normalizedPhone = _normalizePhone(phone);
    final legacy = sha256
        .convert(utf8.encode('$normalizedPhone|$pin|billmaster'))
        .toString();
    return _constantTimeEquals(
      utf8.encode(legacy),
      utf8.encode(storedHash),
    );
  }

  static Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final blockCount = (keyLength + 31) ~/ 32;
    final result = Uint8List(blockCount * 32);
    for (var block = 1; block <= blockCount; block++) {
      final saltBlock = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..[salt.length] = (block >> 24) & 0xff
        ..[salt.length + 1] = (block >> 16) & 0xff
        ..[salt.length + 2] = (block >> 8) & 0xff
        ..[salt.length + 3] = block & 0xff;
      var u = Uint8List.fromList(hmac.convert(saltBlock).bytes);
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      result.setRange((block - 1) * 32, block * 32, t);
    }
    return Uint8List.sublistView(result, 0, keyLength);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  static bool _isValidPin(String value) {
    return RegExp(r'^\d{4}$').hasMatch(value.trim());
  }

  static String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  String _colorForSeed(String seed) {
    const palette = [
      '#0F766E',
      '#1D4ED8',
      '#B45309',
      '#7E22CE',
      '#BE123C',
      '#374151',
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }

  // --- Rate-limiting helpers ---

  bool _isLockedOut(String key) {
    final until = _lockoutUntil[key];
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    // Lockout expired — reset
    _lockoutUntil.remove(key);
    _failedAttempts.remove(key);
    return false;
  }

  void _recordFailedAttempt(String key) {
    final count = (_failedAttempts[key] ?? 0) + 1;
    _failedAttempts[key] = count;
    if (count >= _maxFailedAttempts) {
      _lockoutUntil[key] = DateTime.now().add(_lockoutDuration);
    }
  }

  void _clearFailedAttempts(String key) {
    _failedAttempts.remove(key);
    _lockoutUntil.remove(key);
  }

  void _persistAndNotify() {
    _onChanged?.call();
    notifyListeners();
  }
}
