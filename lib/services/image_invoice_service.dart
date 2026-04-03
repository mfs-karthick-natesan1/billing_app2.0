import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

import '../models/bill.dart';
import '../models/business_config.dart';
import 'pdf_invoice_service.dart';

class ImageInvoiceService {
  ImageInvoiceService._();

  /// Generates a PNG image of the invoice by rasterizing the PDF.
  /// Composites onto a white background so the image looks correct in all apps.
  static Future<Uint8List> generateInvoiceImage({
    required Bill bill,
    required BusinessConfig config,
    double dpi = 150,
    Map<String, String> serialNumberLookup = const {},
  }) async {
    final pdfBytes = await PdfInvoiceService.generateInvoicePdf(
      bill: bill,
      config: config,
      serialNumberLookup: serialNumberLookup,
    );
    final rasterStream = Printing.raster(pdfBytes, dpi: dpi);
    final firstPage = await rasterStream.first;
    final pngBytes = await firstPage.toPng();

    // Composite onto a white background — rasterized PDFs may have a
    // transparent background which renders as black in WhatsApp / gallery.
    final decoded = img.decodeImage(pngBytes);
    if (decoded == null) return pngBytes;

    final canvas = img.Image(
      width: decoded.width,
      height: decoded.height,
    );
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(canvas, decoded);

    return Uint8List.fromList(img.encodePng(canvas));
  }
}
