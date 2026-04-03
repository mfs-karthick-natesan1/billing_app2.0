import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/barcode_scanner_sheet.dart';

abstract class BarcodeScannerService {
  Future<String?> scanBarcode(BuildContext context);
}

class MobileBarcodeScannerService implements BarcodeScannerService {
  const MobileBarcodeScannerService();

  @override
  Future<String?> scanBarcode(BuildContext context) {
    // Barcode scanning is not supported on web
    if (kIsWeb) return Future.value(null);
    return BarcodeScannerSheet.show(context);
  }
}
