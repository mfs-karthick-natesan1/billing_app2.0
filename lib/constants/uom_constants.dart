class UomConstants {
  UomConstants._();

  static const List<String> standardUnits = [
    'pcs',
    'kg',
    'g',
    'ltr',
    'ml',
    'dozen',
    'pack',
    'box',
    'bottle',
  ];

  static const Map<String, String> uomLabels = {
    'pcs': 'Pieces',
    'kg': 'Kilogram',
    'g': 'Gram',
    'ltr': 'Litre',
    'ml': 'Millilitre',
    'dozen': 'Dozen',
    'pack': 'Pack',
    'box': 'Box',
    'bottle': 'Bottle',
    'custom': 'Custom',
  };

  /// Returns the full label for a UOM code. Falls back to the code itself.
  static String label(String uom) => uomLabels[uom] ?? uom;

  /// Formats quantity with UOM for display: "2 kg", "500 ml", "3 pcs".
  /// Displays decimals cleanly — no trailing zeroes.
  static String display(String? uom, double qty) {
    final qtyStr = _formatQty(qty);
    if (uom == null || uom.isEmpty) return qtyStr;
    return '$qtyStr $uom';
  }

  /// Formats quantity without UOM.
  static String formatQty(double qty) => _formatQty(qty);

  static String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    // Show up to 2 decimal places, strip trailing zeroes
    final s = qty.toStringAsFixed(2);
    if (s.endsWith('0')) return s.substring(0, s.length - 1);
    return s;
  }

  /// Whether a UOM typically uses decimal quantities (weight/volume).
  static bool isDecimalUnit(String? uom) {
    return uom == 'kg' || uom == 'g' || uom == 'ltr' || uom == 'ml';
  }
}
