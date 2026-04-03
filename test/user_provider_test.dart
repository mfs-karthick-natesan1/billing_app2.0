import 'package:billing_app/models/user_role.dart';
import 'package:billing_app/providers/user_provider.dart';
import 'package:billing_app/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProvider', () {
    test('single-user mode allows actions by default', () {
      final provider = UserProvider();

      expect(provider.singleUserMode, isTrue);
      expect(provider.canPerform(Permission.manageUsers), isTrue);
      expect(provider.isLoggedIn, isTrue);
    });

    test('create owner enables user management and logs owner in', () {
      final provider = UserProvider();

      final created = provider.createOwnerAndEnableManagement(
        name: 'Owner One',
        phone: '9876543210',
        pin: '1234',
      );

      expect(created, isTrue);
      expect(provider.singleUserMode, isFalse);
      expect(provider.currentUser, isNotNull);
      expect(provider.currentUser!.role, UserRole.owner);
      expect(provider.currentUser!.phone, '9876543210');
      expect(provider.canPerform(Permission.manageUsers), isTrue);
    });

    test('addUser rejects duplicate phone and owner role', () {
      final provider = UserProvider();
      provider.createOwnerAndEnableManagement(
        name: 'Owner',
        phone: '9876543210',
        pin: '1234',
      );

      final duplicate = provider.addUser(
        name: 'Manager',
        phone: '9876543210',
        pin: '1111',
        role: UserRole.manager,
      );
      final ownerRoleForNew = provider.addUser(
        name: 'Other Owner',
        phone: '9123456789',
        pin: '2222',
        role: UserRole.owner,
      );

      expect(duplicate, isFalse);
      expect(ownerRoleForNew, isFalse);
      expect(provider.allUsers.length, 1);
    });

    test('switchUser validates PIN and role permissions update', () {
      final provider = UserProvider();
      provider.createOwnerAndEnableManagement(
        name: 'Owner',
        phone: '9876543210',
        pin: '1234',
      );
      final added = provider.addUser(
        name: 'Billing Staff',
        phone: '9000000001',
        pin: '9999',
        role: UserRole.billing,
      );
      expect(added, isTrue);

      final billingUser = provider.activeUsers.firstWhere(
        (user) => user.role == UserRole.billing,
      );

      expect(provider.switchUser(billingUser.id, '0000'), isFalse);
      expect(provider.switchUser(billingUser.id, '9999'), isTrue);
      expect(provider.currentUser!.id, billingUser.id);
      expect(provider.canPerform(Permission.createBill), isTrue);
      expect(provider.canPerform(Permission.manageUsers), isFalse);
    });

    test('owner cannot be deactivated', () {
      final provider = UserProvider();
      provider.createOwnerAndEnableManagement(
        name: 'Owner',
        phone: '9876543210',
        pin: '1234',
      );

      final ownerId = provider.currentUser!.id;
      expect(provider.deactivateUser(ownerId), isFalse);
      expect(provider.currentUser!.isActive, isTrue);
    });
  });
}
