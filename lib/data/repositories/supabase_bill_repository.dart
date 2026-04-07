import '../../domain/repositories/bill_repository.dart';
import '../../models/bill.dart';
import '../../services/db_service.dart';
import '../../services/supabase_service.dart';

/// Supabase-backed [BillRepository] implementation.
///
/// Currently delegates list/save/delete to the existing [DbService] rather
/// than re-implementing Supabase access — the goal of slice 1 of Sprint 3
/// #24 is to introduce the seam without rewriting the transport. Later
/// slices can collapse DbService into the repository layer once every
/// domain has been migrated.
class SupabaseBillRepository implements BillRepository {
  SupabaseBillRepository(this._db);

  final DbService _db;

  @override
  Future<List<Bill>> loadAll() => _db.loadBills();

  @override
  Future<void> saveAll(List<Bill> bills) => _db.saveBills(bills);

  @override
  Future<void> delete(String id) => _db.deleteRecord('bills', id);

  @override
  Future<dynamic> completeBillRpc({
    required String businessId,
    required Map<String, dynamic> bill,
    required List<Map<String, dynamic>> stockChanges,
    Map<String, dynamic>? credit,
    required String prefix,
    required bool useServerBillNumber,
  }) {
    return SupabaseService.client.rpc(
      'complete_bill',
      params: {
        'p_business_id': businessId,
        'p_bill': bill,
        'p_stock_changes': stockChanges,
        if (credit != null) 'p_credit': credit,
        'p_prefix': prefix,
        'p_use_server_bill_number': useServerBillNumber,
      },
    );
  }
}
