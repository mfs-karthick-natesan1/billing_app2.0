enum UserRole { owner, manager, billing, viewer }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Manager';
      case UserRole.billing:
        return 'Billing Staff';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.manager:
        return 'Mgr';
      case UserRole.billing:
        return 'Billing';
      case UserRole.viewer:
        return 'View';
    }
  }
}
