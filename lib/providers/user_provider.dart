import 'dart:convert';

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
    if (user.pinHash != hashPin(pin, phone: user.phone)) {
      _recordFailedAttempt(userId);
      return false;
    }

    _clearFailedAttempts(userId);
    final updated = user.copyWith(lastLoginAt: DateTime.now());
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

    if (hashPin(pin, phone: user.phone) != user.pinHash) {
      _recordFailedAttempt(user.id);
      return false;
    }
    _clearFailedAttempts(user.id);
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

  static String hashPin(String pin, {required String phone}) {
    final normalizedPhone = _normalizePhone(phone);
    final digest = sha256.convert(
      utf8.encode('$normalizedPhone|$pin|billmaster'),
    );
    return digest.toString();
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
