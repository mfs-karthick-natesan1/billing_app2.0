import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';

class BarcodeScannerSheet extends StatefulWidget {
  final MobileScannerController? controller;

  const BarcodeScannerSheet({super.key, this.controller});

  static Future<String?> show(
    BuildContext context, {
    MobileScannerController? controller,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerSheet(controller: controller),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  late final MobileScannerController _controller;
  late final bool _ownsController;
  bool _barcodeHandled = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
          facing: CameraFacing.back,
        );
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_barcodeHandled) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        _barcodeHandled = true;
        Navigator.of(context).pop(value);
        return;
      }
    }
  }

  Future<void> _enterBarcodeManually() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.enterBarcode),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: AppStrings.barcodeHint),
            onSubmitted: (value) {
              final normalized = value.trim();
              Navigator.of(context).pop(normalized.isEmpty ? null : normalized);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () {
                final normalized = controller.text.trim();
                Navigator.of(
                  context,
                ).pop(normalized.isEmpty ? null : normalized);
              },
              child: const Text(AppStrings.useBarcode),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted || result == null) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.small),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.muted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: Row(
              children: [
                Text(
                  AppStrings.scanBarcode,
                  style: AppTypography.heading.copyWith(fontSize: 20),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            child: Text(
              AppStrings.scanBarcodeDescription,
              style: AppTypography.label,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(controller: _controller, onDetect: _onDetect),
                    Center(
                      child: Container(
                        width: 240,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: TextButton.icon(
              onPressed: _enterBarcodeManually,
              icon: const Icon(Icons.keyboard_alt_outlined),
              label: const Text(AppStrings.enterBarcodeManually),
            ),
          ),
        ],
      ),
    );
  }
}
