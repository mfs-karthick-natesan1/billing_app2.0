import 'uom_constants.dart';

class Units {
  Units._();

  static const List<String> all = [
    'pcs',
    'kg',
    'g',
    'ltr',
    'ml',
    'dozen',
    'pack',
    'box',
    'bottle',
    'custom',
  ];

  static const String defaultUnit = 'pcs';

  /// Returns a user-friendly label for a unit code.
  static String label(String unit) => UomConstants.label(unit);
}
