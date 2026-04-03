import 'package:billing_app/models/user_role.dart';
import 'package:billing_app/providers/user_provider.dart';
import 'package:billing_app/widgets/add_edit_user_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('owner setup initializes role dropdown with owner value', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const MaterialApp(
          home: Scaffold(body: AddEditUserSheet(ownerSetup: true)),
        ),
      ),
    );

    final error = tester.takeException();
    expect(error, isNull);

    final dropdown = tester.widget<DropdownButton<UserRole>>(
      find.byType(DropdownButton<UserRole>),
    );
    expect(dropdown.value, UserRole.owner);
  });
}
