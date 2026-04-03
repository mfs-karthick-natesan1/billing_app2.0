import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On web, centers [child] within a max-width box so content doesn't stretch
/// across very wide monitors. On mobile it's a transparent pass-through.
class WebConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebConstraint({
    super.key,
    required this.child,
    this.maxWidth = 960,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
