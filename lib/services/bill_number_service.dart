class BillNumberService {
  int _counter = 0;
  String? _currentFy;

  String get currentFinancialYear {
    final now = DateTime.now();
    final int startYear;
    if (now.month >= 4) {
      startYear = now.year;
    } else {
      startYear = now.year - 1;
    }
    final endYear = (startYear + 1) % 100;
    return '$startYear-${endYear.toString().padLeft(2, '0')}';
  }

  String generateBillNumber({String prefix = 'INV'}) {
    final fy = currentFinancialYear;
    if (_currentFy != fy) {
      _currentFy = fy;
      _counter = 0;
    }
    _counter++;
    final number = _counter.toString().padLeft(3, '0');
    return '$fy/$prefix-$number';
  }

  int get currentCounter => _counter;

  void hydrateFromExistingBills(List<String> billNumbers) {
    final fy = currentFinancialYear;
    _currentFy = fy;
    var maxCounter = 0;

    for (final billNumber in billNumbers) {
      if (!billNumber.startsWith('$fy/')) continue;
      final parts = billNumber.split('-');
      if (parts.isEmpty) continue;
      final number = int.tryParse(parts.last) ?? 0;
      if (number > maxCounter) {
        maxCounter = number;
      }
    }

    _counter = maxCounter;
  }
}
