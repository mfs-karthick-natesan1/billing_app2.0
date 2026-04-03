import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product.dart';
import '../constants/categories.dart';
import '../constants/units.dart';
import '../constants/gst_slabs.dart';

class CsvValidationResult {
  final List<Product> validProducts;
  final List<CsvError> errors;

  CsvValidationResult({required this.validProducts, required this.errors});
}

class CsvError {
  final int row;
  final String message;

  CsvError({required this.row, required this.message});
}

class CsvService {
  static const _expectedHeaders = [
    'product_name',
    'selling_price',
    'stock_quantity',
    'category',
    'unit',
    'gst_slab',
  ];

  static const _templateContent =
      '''product_name,selling_price,stock_quantity,category,unit,gst_slab
Rice Basmati 1kg,85,50,Grains & Pulses,kg,5
Tata Salt 1kg,28,100,Cooking Essentials,pcs,0
Amul Butter 500g,280,15,Dairy,pcs,12''';

  static Future<String> generateTemplate() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/billmaster_template.csv');
    await file.writeAsString(_templateContent);
    return file.path;
  }

  static CsvValidationResult parseAndValidate(
    String csvContent, {
    List<String> existingProductNames = const [],
  }) {
    // Normalise line endings so both \r\n and \n files are handled correctly.
    final normalised = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(eol: '\n').convert(normalised);
    if (rows.isEmpty) {
      return CsvValidationResult(
        validProducts: [],
        errors: [CsvError(row: 0, message: 'Empty CSV file')],
      );
    }

    // Validate headers
    final headers = rows[0]
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    if (!_headersMatch(headers)) {
      return CsvValidationResult(
        validProducts: [],
        errors: [
          CsvError(
            row: 1,
            message: 'Invalid CSV format. Please use the provided template.',
          ),
        ],
      );
    }

    final validProducts = <Product>[];
    final errors = <CsvError>[];
    final seenNames = <String>{};
    final existingLower = existingProductNames
        .map((n) => n.toLowerCase())
        .toSet();

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty ||
          (row.length == 1 && row[0].toString().trim().isEmpty)) {
        continue; // skip empty rows
      }

      final rowNum = i + 1;

      if (row.length < 2) {
        errors.add(CsvError(row: rowNum, message: 'Incomplete row'));
        continue;
      }

      // Product name
      final name = row[0].toString().trim();
      if (name.isEmpty) {
        errors.add(CsvError(row: rowNum, message: 'Product name is required'));
        continue;
      }
      if (name.length < 2) {
        errors.add(CsvError(row: rowNum, message: 'Name too short'));
        continue;
      }
      if (seenNames.contains(name.toLowerCase())) {
        errors.add(
          CsvError(row: rowNum, message: 'Duplicate product name in file'),
        );
        continue;
      }
      if (existingLower.contains(name.toLowerCase())) {
        errors.add(CsvError(row: rowNum, message: 'Product already exists'));
        continue;
      }

      // Selling price
      final priceStr = row.length > 1 ? row[1].toString().trim() : '';
      final price = double.tryParse(priceStr);
      if (price == null || price <= 0) {
        errors.add(
          CsvError(
            row: rowNum,
            message: priceStr.isEmpty ? 'Price is required' : 'Invalid price',
          ),
        );
        continue;
      }

      // Stock quantity
      int stock = 0;
      if (row.length > 2) {
        final stockStr = row[2].toString().trim();
        if (stockStr.isNotEmpty) {
          final parsed = int.tryParse(stockStr);
          if (parsed == null) {
            errors.add(CsvError(row: rowNum, message: 'Invalid stock'));
            continue;
          }
          stock = parsed < 0 ? 0 : parsed; // clamp negative to 0
        }
      }

      // Category (optional, defaults to Other)
      // Accept any non-empty string; match known categories case-insensitively,
      // but store as-is if not found (allows custom workshop/business categories).
      String? category;
      if (row.length > 3) {
        final cat = row[3].toString().trim();
        if (cat.isNotEmpty) {
          final matched = Categories.all.firstWhere(
            (c) => c.toLowerCase() == cat.toLowerCase(),
            orElse: () => '',
          );
          category = matched.isNotEmpty ? matched : cat;
        }
      }

      // Unit (optional, defaults to pcs)
      String unit = Units.defaultUnit;
      if (row.length > 4) {
        final u = row[4].toString().trim();
        if (u.isNotEmpty) {
          unit = Units.all.firstWhere(
            (un) => un.toLowerCase() == u.toLowerCase(),
            orElse: () => Units.defaultUnit,
          );
        }
      }

      // GST slab (optional, defaults to 0)
      int gstSlab = GstSlabs.defaultSlab;
      if (row.length > 5) {
        final gst = int.tryParse(row[5].toString().trim());
        if (gst != null && GstSlabs.all.contains(gst)) {
          gstSlab = gst;
        }
      }

      seenNames.add(name.toLowerCase());
      validProducts.add(
        Product(
          name: name,
          sellingPrice: price,
          stockQuantity: stock,
          category: category,
          unit: unit,
          gstSlabPercent: gstSlab,
        ),
      );
    }

    return CsvValidationResult(validProducts: validProducts, errors: errors);
  }

  static bool _headersMatch(List<String> headers) {
    if (headers.length < 2) return false;
    // At minimum, first two headers must match
    return headers[0] == _expectedHeaders[0] &&
        headers[1] == _expectedHeaders[1];
  }
}
