import 'package:flutter/foundation.dart';
import '../models/serial_number.dart';

class SerialNumberProvider extends ChangeNotifier {
  List<SerialNumber> _records = [];
  VoidCallback? _onChanged;

  void init(List<SerialNumber> initial, VoidCallback onChanged) {
    _records = List.from(initial);
    _onChanged = onChanged;
  }

  List<SerialNumber> get all => List.unmodifiable(_records);

  List<SerialNumber> forProduct(String productId) =>
      _records.where((s) => s.productId == productId).toList();

  List<SerialNumber> availableFor(String productId) => _records
      .where((s) => s.productId == productId && s.status == SerialNumberStatus.inStock)
      .toList();

  bool isNumberDuplicate(String productId, String number) => _records.any(
    (s) => s.productId == productId && s.number.toLowerCase() == number.toLowerCase(),
  );

  void addFromPurchase({
    required List<String> numbers,
    required String productId,
    required String productName,
    required String purchaseEntryId,
  }) {
    for (final n in numbers) {
      final trimmed = n.trim();
      if (trimmed.isEmpty) continue;
      _records.add(SerialNumber(
        productId: productId,
        productName: productName,
        number: trimmed,
        purchaseEntryId: purchaseEntryId,
      ));
    }
    notifyListeners();
    _onChanged?.call();
  }

  void assignToBill(List<String> serialNumberIds, String billId) {
    for (final id in serialNumberIds) {
      final idx = _records.indexWhere((s) => s.id == id);
      if (idx >= 0) {
        _records[idx].status = SerialNumberStatus.sold;
        _records[idx].billId = billId;
      }
    }
    notifyListeners();
    _onChanged?.call();
  }

  void returnFromBill(String billId) {
    for (final s in _records) {
      if (s.billId == billId && s.status == SerialNumberStatus.sold) {
        s.status = SerialNumberStatus.returned;
      }
    }
    notifyListeners();
    _onChanged?.call();
  }

  void loadAll(List<SerialNumber> records) {
    _records = List.from(records);
    notifyListeners();
  }
}
