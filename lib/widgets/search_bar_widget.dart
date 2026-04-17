import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
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
  // Set to false to suppress the mic button on surfaces that don't
  // need voice input (e.g. embedded search inside another form).
  final bool voiceSearch;

  const SearchBarWidget({
    super.key,
    this.hint = AppStrings.searchProducts,
    required this.onSearch,
    required this.onProductSelected,
    this.onScanBarcode,
    this.autofocus = false,
    this.focusNode,
    this.voiceSearch = true,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final FocusNode _focusNode;
  List<Product> _results = [];
  bool _showResults = false;

  // Voice search
  final _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    // Pulse controller only animates while _isListening; stopped by default
    // so it does not leak timers in widget tests.
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.voiceSearch) _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onError: (_) => _setListening(false),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _setListening(false);
          }
        },
      );
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      // Plugin not available in test / web environments — hide the mic button.
    }
  }

  void _setListening(bool value) {
    if (!mounted) return;
    setState(() => _isListening = value);
    if (value) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController
        ..stop()
        ..reset();
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      _setListening(false);
      return;
    }
    _setListening(true);
    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        _controller.text = text;
        _onChanged(text);
        if (result.finalResult) {
          _setListening(false);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_IN',
      partialResults: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (query.length >= 1) {
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
    final showMic = widget.voiceSearch && _speechAvailable;
    final hasSuffix = _controller.text.isNotEmpty ||
        widget.onScanBarcode != null ||
        showMic;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: _isListening
                  ? AppColors.error.withValues(alpha: 0.6)
                  : AppColors.muted.withValues(alpha: 0.2),
              width: _isListening ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            onChanged: _onChanged,
            style: AppTypography.body,
            decoration: InputDecoration(
              hintText: _isListening ? 'Listening…' : widget.hint,
              hintStyle: AppTypography.body.copyWith(
                color: _isListening ? AppColors.error : AppColors.muted,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.muted,
                size: 24,
              ),
              suffixIcon: hasSuffix
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
                        if (showMic)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (_, __) {
                              final opacity = _isListening
                                  ? 0.4 + 0.6 * _pulseController.value
                                  : 1.0;
                              return IconButton(
                                icon: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: _isListening
                                      ? AppColors.error.withValues(
                                          alpha: opacity,
                                        )
                                      : AppColors.primary,
                                  size: 24,
                                ),
                                tooltip: _isListening
                                    ? 'Tap to stop'
                                    : 'Search by voice',
                                onPressed: _toggleListening,
                              );
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
