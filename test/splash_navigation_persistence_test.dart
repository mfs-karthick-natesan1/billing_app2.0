import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/providers/business_config_provider.dart';
import 'package:billing_app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _buildApp(BusinessConfigProvider provider) {
  return ChangeNotifierProvider<BusinessConfigProvider>.value(
    value: provider,
    child: MaterialApp(
      home: const SplashScreen(),
      routes: {
        '/home': (_) => const Scaffold(body: Text('HOME_SCREEN')),
        '/setup': (_) => const Scaffold(body: Text('SETUP_SCREEN')),
      },
    ),
  );
}

void main() {
  testWidgets('navigates to home when setup is completed', (tester) async {
    final provider = BusinessConfigProvider(
      initialConfig: const BusinessConfig(
        setupCompleted: true,
        businessName: 'Persisted Shop',
      ),
    );

    await tester.pumpWidget(_buildApp(provider));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('HOME_SCREEN'), findsOneWidget);
    expect(find.text('SETUP_SCREEN'), findsNothing);
  });

  testWidgets('navigates to setup when setup is not completed', (tester) async {
    final provider = BusinessConfigProvider(
      initialConfig: const BusinessConfig(setupCompleted: false),
    );

    await tester.pumpWidget(_buildApp(provider));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('SETUP_SCREEN'), findsOneWidget);
    expect(find.text('HOME_SCREEN'), findsNothing);
  });
}
