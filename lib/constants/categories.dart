import '../models/business_config.dart';

class Categories {
  Categories._();

  static const List<String> mobileShop = [
    'Smartphones',
    'Feature Phones',
    'Used / Second Hand',
    'Spare Parts',
    'Accessories',
    'Repair Services',
    'Chargers & Cables',
    'Screen Guards & Cases',
    'Other',
  ];

  static const List<String> general = [
    'Grains & Pulses',
    'Dairy',
    'Snacks & Beverages',
    'Cooking Essentials',
    'Personal Care',
    'Household',
    'Frozen',
    'Other',
  ];

  static const List<String> pharmacy = [
    'Tablets',
    'Capsules',
    'Syrups',
    'Injections',
    'Ointments',
    'Drops',
    'Supplements',
    'Medical Devices',
    'Other',
  ];

  static const List<String> salon = [
    'Hair',
    'Skin Care',
    'Massage',
    'Nails',
    'Products',
    'Other',
  ];

  static const List<String> clinic = [
    'Consultation',
    'Lab',
    'Imaging',
    'Procedure',
    'Diagnostic',
    'Therapy',
    'Supplies',
    'Other',
  ];

  static const List<String> jewellery = [
    'Gold',
    'Silver',
    'Diamond',
    'Platinum',
    'Gemstones',
    'Fashion Jewellery',
    'Accessories',
    'Other',
  ];

  static const List<String> restaurant = [
    'Starters',
    'Main Course',
    'Breads',
    'Rice & Biryani',
    'Curries',
    'Beverages',
    'Desserts',
    'Snacks',
    'Other',
  ];

  static const List<String> all = general;

  static List<String> forBusinessType(BusinessType type) {
    switch (type) {
      case BusinessType.pharmacy:
        return pharmacy;
      case BusinessType.salon:
        return salon;
      case BusinessType.clinic:
        return clinic;
      case BusinessType.jewellery:
        return jewellery;
      case BusinessType.restaurant:
        return restaurant;
      case BusinessType.mobileShop:
        return mobileShop;
      case BusinessType.general:
      case BusinessType.workshop:
        return general;
    }
  }

  /// Returns the list for the given business type, ensuring [current]
  /// is included (handles products with categories from a different type).
  static List<String> forBusinessTypeWithCurrent(
    BusinessType type,
    String? current,
  ) {
    final list = forBusinessType(type);
    if (current == null || list.contains(current)) return list;
    return [current, ...list];
  }
}
