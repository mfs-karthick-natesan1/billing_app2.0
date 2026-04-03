import 'package:billing_app/models/user_role.dart';
import 'package:billing_app/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PermissionService', () {
    test('owner has all permissions', () {
      for (final permission in Permission.values) {
        expect(
          PermissionService.canPerform(UserRole.owner, permission),
          isTrue,
          reason: 'Owner should have ${permission.name}',
        );
      }
    });

    test('billing staff cannot delete products or expenses', () {
      expect(
        PermissionService.canPerform(
          UserRole.billing,
          Permission.deleteProduct,
        ),
        isFalse,
      );
      expect(
        PermissionService.canPerform(
          UserRole.billing,
          Permission.deleteExpense,
        ),
        isFalse,
      );
      expect(
        PermissionService.canPerform(UserRole.billing, Permission.createBill),
        isTrue,
      );
    });

    test('viewer has read-only access to key sections', () {
      expect(
        PermissionService.hasAccessTo(UserRole.viewer, AppSection.billing),
        isTrue,
      );
      expect(
        PermissionService.hasAccessTo(UserRole.viewer, AppSection.products),
        isTrue,
      );
      expect(
        PermissionService.hasAccessTo(
          UserRole.viewer,
          AppSection.userManagement,
        ),
        isFalse,
      );
      expect(
        PermissionService.canPerform(UserRole.viewer, Permission.createBill),
        isFalse,
      );
    });
  });
}
