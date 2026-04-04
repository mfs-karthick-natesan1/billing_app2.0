import 'supabase_service.dart';

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

  /// Generates a bill number using the Supabase `get_next_bill_number` RPC,
  /// which atomically sequences numbers per business and financial year.
  /// Falls back to the local in-memory counter when offline or businessId is
  /// unavailable.
  Future<String> generateBillNumberAsync({
    required String? businessId,
    String prefix = 'INV',
  }) async {
    if (businessId != null) {
      try {
        final result = await SupabaseService.client.rpc(
          'get_next_bill_number',
          params: {
            'p_business_id': businessId,
            'p_prefix': prefix,
          },
        );
        if (result is String && result.isNotEmpty) {
          return result;
        }
      } catch (_) {
        // Offline or RPC unavailable — fall through to local fallback
      }
    }
    return generateBillNumber(prefix: prefix);
  }

  /// Local fallback: generates a bill number using an in-memory counter.
  /// Used when offline or when businessId is not available.
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
