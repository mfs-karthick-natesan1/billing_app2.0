import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/csv_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  int _step = 1; // 1=select, 2=preview, 3=done
  List<Product> _validProducts = [];
  List<CsvError> _errors = [];
  int _importedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: _step == 1
            ? AppStrings.importProducts
            : _step == 2
            ? AppStrings.previewImport
            : AppStrings.importComplete,
        showBack: true,
      ),
      body: _step == 1
          ? _buildStep1()
          : _step == 2
          ? _buildStep2()
          : _buildStep3(),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.upload_file, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'Import products from a CSV file',
            style: AppTypography.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            AppStrings.importDesc,
            style: AppTypography.body.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.large),
          OutlinedButton(
            onPressed: _downloadTemplate,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              AppStrings.downloadTemplate,
              style: AppTypography.body.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: Text(
                AppStrings.selectCsvFile,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: RichText(
            text: TextSpan(
              style: AppTypography.body,
              children: [
                TextSpan(text: '${_validProducts.length} products found. '),
                if (_errors.isNotEmpty)
                  TextSpan(
                    text: '${_errors.length} errors.',
                    style: AppTypography.body.copyWith(color: AppColors.error),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            children: [
              if (_validProducts.isNotEmpty) ...[
                Text(
                  'Valid Products',
                  style: AppTypography.heading.copyWith(fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.small),
                ..._validProducts.map(
                  (p) => Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.muted.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: AppTypography.body,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          Formatters.currency(p.sellingPrice),
                          style: AppTypography.currency,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Text('${p.stockQuantity}', style: AppTypography.label),
                      ],
                    ),
                  ),
                ),
              ],
              if (_errors.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.medium),
                Text(
                  '${_errors.length} rows have errors',
                  style: AppTypography.label.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.small),
                ..._errors.map(
                  (e) => Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight(0.05),
                      border: Border.all(color: AppColors.errorLight(0.2)),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Row ${e.row}: ${e.message}',
                      style: AppTypography.label.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _validProducts.isNotEmpty ? _import : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.muted.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.buttonRadius,
                    ),
                  ),
                ),
                child: Text(
                  'Import ${_validProducts.length} Products',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _validProducts.isNotEmpty
                        ? Colors.white
                        : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 48, color: AppColors.success),
          const SizedBox(height: AppSpacing.medium),
          Text(
            '$_importedCount ${AppStrings.productsImported}',
            style: AppTypography.heading.copyWith(color: AppColors.success),
            textAlign: TextAlign.center,
          ),
          if (_errors.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              '${_errors.length} ${AppStrings.rowsSkipped}',
              style: AppTypography.label.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: Text(
                AppStrings.viewProducts,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadTemplate() async {
    try {
      final path = await CsvService.generateTemplate();
      if (mounted) {
        AppSnackbar.success(context, 'Template saved to $path');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to save template');
      }
    }
  }

  void _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: kIsWeb, // on web, load bytes directly (no file path)
    );
    if (result == null || result.files.isEmpty) return;

    try {
      const maxBytes = 1 * 1024 * 1024; // 1 MB
      final fileSize = result.files.first.size;
      if (fileSize > maxBytes) {
        if (mounted) {
          AppSnackbar.error(context, AppStrings.csvFileTooLarge);
        }
        return;
      }

      String content;
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) return;
        content = utf8.decode(bytes, allowMalformed: true);
      } else {
        final filePath = result.files.first.path;
        if (filePath == null) return;
        content = await File(filePath).readAsString();
      }
      if (!mounted) return;
      final productProvider = context.read<ProductProvider>();
      final existingNames = productProvider.products
          .map((p) => p.name)
          .toList();

      final validation = CsvService.parseAndValidate(
        content,
        existingProductNames: existingNames,
      );

      setState(() {
        _validProducts = validation.validProducts;
        _errors = validation.errors;
        _step = 2;
      });
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, AppStrings.invalidCsvFormat);
      }
    }
  }

  void _import() {
    final productProvider = context.read<ProductProvider>();
    productProvider.importProducts(_validProducts);
    setState(() {
      _importedCount = _validProducts.length;
      _step = 3;
    });
  }
}
