class GstSlabs {
  GstSlabs._();

  static const List<int> all = [0, 3, 5, 12, 18, 28];

  static const int defaultSlab = 0;

  static String label(int slab) => '$slab%';
}
