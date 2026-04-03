import 'package:billing_app/widgets/app_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFab', () {
    testWidgets('disables hero animation by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(floatingActionButton: AppFab(onPressed: () {})),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.heroTag, isNull);
    });

    testWidgets('supports explicit hero tag when provided', (tester) async {
      const heroTag = 'products-fab';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AppFab(onPressed: () {}, heroTag: heroTag),
          ),
        ),
      );

      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.heroTag, heroTag);
    });
  });
}
