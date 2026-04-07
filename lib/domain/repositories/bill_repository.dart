import '../../models/bill.dart';

/// Abstract bill persistence contract.
///
/// Introduced as the first slice of Sprint 3 #24 (repository pattern).
/// Providers should depend on this interface so they can be tested with
/// in-memory fakes and so the Supabase-specific wiring (DbService +
/// complete_bill RPC) stays isolated to a single adapter under
/// `lib/data/repositories/`.
abstract class BillRepository {
  /// Fetch every bill that belongs to the current business.
  Future<List<Bill>> loadAll();

  /// Upsert one or more bills. Must complete in order with respect to
  /// previous calls so that the BillProvider `pendingSave` chain keeps
  /// its serialisation guarantee.
  Future<void> saveAll(List<Bill> bills);

  /// Hard-delete a bill by id.
  Future<void> delete(String id);

  /// Invoke the atomic `complete_bill` Supabase RPC. Returns the raw
  /// server response so the caller can decide whether the server
  /// already applied the stock/credit side-effects.
  Future<dynamic> completeBillRpc({
    required String businessId,
    required Map<String, dynamic> bill,
    required List<Map<String, dynamic>> stockChanges,
    Map<String, dynamic>? credit,
    required String prefix,
    required bool useServerBillNumber,
  });
}
