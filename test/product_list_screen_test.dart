import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/business_config_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/screens/product_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _buildScreen(ProductProvider productProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
      ChangeNotifierProvider<BusinessConfigProvider>(
        create: (_) => BusinessConfigProvider(
          initialConfig: const BusinessConfig(
            businessName: 'Test Shop',
            setupCompleted: true,
          ),
        ),
      ),
    ],
    child: const MaterialApp(home: ProductListScreen()),
  );
}

void main() {
  group('ProductListScreen — rendering', () {
    testWidgets('shows empty state when no products', (tester) async {
      await tester.pumpWidget(_buildScreen(ProductProvider()));
      await tester.pumpAndSettle();

      expect(find.byType(ProductListScreen), findsOneWidget);
      // Should show empty state
      expect(find.text(AppStrings.noProductsYet), findsOneWidget);
    });

    testWidgets('shows product cards for each product', (tester) async {
      final pp = ProductProvider(
        initialProducts: [
          Product(name: 'Rice 5kg', sellingPrice: 250, stockQuantity: 100),
          Product(name: 'Sugar 1kg', sellingPrice: 45, stockQuantity: 50),
          Product(name: 'Oil 1L', sellingPrice: 180, stockQuantity: 30),
        ],
      );

      await tester.pumpWidget(_buildScreen(pp));
      await tester.pumpAndSettle();

      expect(find.text('Rice 5kg'), findsOneWidget);
      expect(find.text('Sugar 1kg'), findsOneWidget);
      expect(find.text('Oil 1L'), findsOneWidget);
    });

    testWidgets('shows product count in list', (tester) async {
      final pp = ProductProvider(
        initialProducts: [
          Product(name: 'Product A', sellingPrice: 100, stockQuantity: 10),
          Product(name: 'Product B', sellingPrice: 200, stockQuantity: 20),
        ],
      );

      await tester.pumpWidget(_buildScreen(pp));
      await tester.pumpAndSettle();

      expect(find.text('Product A'), findsOneWidget);
      expect(find.text('Product B'), findsOneWidget);
    });
  });

  group('ProductListScreen — search', () {
    testWidgets('search filters products by name', (tester) async {
      final pp = ProductProvider(
        initialProducts: [
          Product(name: 'Rice 5kg', sellingPrice: 250, stockQuantity: 100),
          Product(name: 'Sugar 1kg', sellingPrice: 45, stockQuantity: 50),
        ],
      );

      await tester.pumpWidget(_buildScreen(pp));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Rice');
      await tester.pump();

      expect(find.text('Rice 5kg'), findsOneWidget);
      expect(find.text('Sugar 1kg'), findsNothing);
    });

    testWidgets('clearing search shows all products again', (tester) async {
      final pp = ProductProvider(
        initialProducts: [
          Product(name: 'Rice 5kg', sellingPrice: 250, stockQuantity: 100),
          Product(name: 'Sugar 1kg', sellingPrice: 45, stockQuantity: 50),
        ],
      );

      await tester.pumpWidget(_buildScreen(pp));
      await tester.pumpAndSettle();

      // Type something
      await tester.enterText(find.byType(TextField).first, 'Rice');
      await tester.pump();
      expect(find.text('Sugar 1kg'), findsNothing);

      // Clear
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pump();

      expect(find.text('Rice 5kg'), findsOneWidget);
      expect(find.text('Sugar 1kg'), findsOneWidget);
    });

    testWidgets('search with no match shows empty state', (tester) async {
      final pp = ProductProvider(
        initialProducts: [
          Product(name: 'Rice 5kg', sellingPrice: 250, stockQuantity: 100),
        ],
      );

      await tester.pumpWidget(_buildScreen(pp));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'XYZ Nonexistent');
      await tester.pump();

      expect(find.text('Rice 5kg'), findsNothing);
    });
  });

  group('ProductListScreen — low stock filter', () {
    testWidgets('low stock filter shows only low-stock products', (
      tester,
    ) async {
      final pp = ProductProvider(
        initialProducts: [
          Product(
            name: 'Low Stock Item',
            sellingPrice: 100,
            stockQuantity: 2,
            reorderLevel: 5,
          ),
          Product(
            name: 'Normal Stock Item',
            sellingPrice: 100,
            stockQuantity: 50,
            reorderLevel: 5,
          ),
        ],
      );

      await tester.pumpWidget(_buildScreen(pp));
      await tester.pumpAndSettle();

      // Tap the Low Stock filter chip (label is "Low Stock (N)") — use first
      // because product cards also contain "Low Stock: N pcs" indicator text
      await tester.tap(find.textContaining('Low Stock (').first);
      await tester.pump();

      expect(find.text('Low Stock Item'), findsOneWidget);
      expect(find.text('Normal Stock Item'), findsNothing);
    });
  });
}
