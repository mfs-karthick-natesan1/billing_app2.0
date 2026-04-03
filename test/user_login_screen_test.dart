import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/app_user.dart';
import 'package:billing_app/models/user_role.dart';
import 'package:billing_app/providers/navigation_provider.dart';
import 'package:billing_app/providers/user_provider.dart';
import 'package:billing_app/screens/user_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  AppUser buildUser({
    required String id,
    required String name,
    required String phone,
    required String pin,
    required UserRole role,
  }) {
    return AppUser(
      id: id,
      name: name,
      phone: phone,
      pinHash: UserProvider.hashPin(pin, phone: phone),
      role: role,
      avatarColor: '#0F766E',
    );
  }

  testWidgets('logs in selected user with valid PIN', (tester) async {
    final userProvider = UserProvider(
      initialUsers: [
        buildUser(
          id: 'u1',
          name: 'Owner',
          phone: '9876543210',
          pin: '1234',
          role: UserRole.owner,
        ),
        buildUser(
          id: 'u2',
          name: 'Billing',
          phone: '9000000001',
          pin: '9999',
          role: UserRole.billing,
        ),
      ],
      singleUserMode: false,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ],
        child: MaterialApp(
          routes: {
            '/login': (_) => const UserLoginScreen(),
            '/home': (_) => const Scaffold(body: Text('HOME')),
          },
          initialRoute: '/login',
        ),
      ),
    );

    expect(find.text(AppStrings.selectUser), findsOneWidget);
    await tester.tap(find.text('Billing').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('9').first);
    await tester.tap(find.text('9').first);
    await tester.tap(find.text('9').first);
    await tester.tap(find.text('9').first);
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(userProvider.currentUser?.name, 'Billing');
  });

  testWidgets('shows wrong PIN error on invalid PIN', (tester) async {
    final userProvider = UserProvider(
      initialUsers: [
        buildUser(
          id: 'u1',
          name: 'Owner',
          phone: '9876543210',
          pin: '1234',
          role: UserRole.owner,
        ),
      ],
      singleUserMode: false,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ],
        child: const MaterialApp(home: UserLoginScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('1').first);
    await tester.tap(find.text('1').first);
    await tester.tap(find.text('1').first);
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.wrongPin), findsOneWidget);
    expect(userProvider.currentUser, isNull);
  });
}
