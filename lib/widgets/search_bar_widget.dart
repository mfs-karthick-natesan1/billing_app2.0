import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/product.dart';

class SearchBarWidget extends StatefulWidget {
  final String hint;
  final List<Product> Function(String query) onSearch;
  final ValueChanged<Product> onProductSelected;
  final VoidCallback? onScanBarcode;
  final bool autofocus;
  final FocusNode? focusNode;

  const SearchBarWidget({
    super.key,
    this.hint = AppStrings.searchProducts,
    required this.onSearch,
    required this.onProductSelected,
    this.onScanBarcode,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  List<Product> _results = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (query.length >= 2) {
      setState(() {
        _results = widget.onSearch(query);
        _showResults = true;
      });
    } else {
      setState(() {
        _results = [];
        _showResults = false;
      });
    }
  }

  void _selectProduct(Product product) {
    widget.onProductSelected(product);
    _controller.clear();
    setState(() {
      _results = [];
      _showResults = false;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            onChanged: _onChanged,
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.body.copyWith(color: AppColors.muted),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.muted,
                size: 24,
              ),
              suffixIcon:
                  _controller.text.isNotEmpty || widget.onScanBarcode != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.muted,
                              size: 24,
                            ),
                            onPressed: () {
                              _controller.clear();
                              _onChanged('');
                            },
                          ),
                        if (widget.onScanBarcode != null)
                          IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            onPressed: widget.onScanBarcode,
                            tooltip: AppStrings.scanBarcode,
                          ),
                      ],
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (_showResults)
          Container(
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.cardRadius),
                bottomRight: Radius.circular(AppSpacing.cardRadius),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _results.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.medium),
                    child: Text(
                      AppStrings.noProductsFound,
                      style: AppTypography.label,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final product = _results[index];
                      return InkWell(
                        onTap: () => _selectProduct(product),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: AppTypography.body,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                Formatters.currency(product.sellingPrice),
                                style: AppTypography.currency,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
