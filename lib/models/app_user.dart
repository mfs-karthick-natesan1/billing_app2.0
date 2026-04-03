import 'package:uuid/uuid.dart';

import 'user_role.dart';

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String pinHash;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? lastLoginAt;
  final String avatarColor;

  AppUser({
    String? id,
    required this.name,
    required this.phone,
    required this.pinHash,
    required this.role,
    this.isActive = true,
    DateTime? createdAt,
    this.createdBy,
    this.lastLoginAt,
    required this.avatarColor,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? pinHash,
    UserRole? role,
    bool? isActive,
    String? createdBy,
    DateTime? lastLoginAt,
    bool clearLastLoginAt = false,
    String? avatarColor,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      pinHash: pinHash ?? this.pinHash,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      createdBy: createdBy ?? this.createdBy,
      lastLoginAt: clearLastLoginAt ? null : (lastLoginAt ?? this.lastLoginAt),
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'pinHash': pinHash,
      'role': role.name,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'avatarColor': avatarColor,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      pinHash: json['pinHash'] as String? ?? '',
      role: _roleFromString(json['role'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      createdBy: json['createdBy'] as String?,
      lastLoginAt: DateTime.tryParse(json['lastLoginAt'] as String? ?? ''),
      avatarColor: json['avatarColor'] as String? ?? '#0F766E',
    );
  }

  static UserRole _roleFromString(String? value) {
    if (value == null) return UserRole.viewer;
    for (final role in UserRole.values) {
      if (role.name == value) return role;
    }
    return UserRole.viewer;
  }
}
