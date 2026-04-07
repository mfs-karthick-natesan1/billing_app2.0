import '../../models/bill.dart';
import '../repositories/bill_repository.dart';

/// Result of running [CompleteBillUseCase.execute].
///
/// [rpcSucceeded] is true when the atomic `complete_bill` Supabase RPC
/// returned successfully. Callers use this to decide whether peer
/// providers (product stock, customer credit) should persist their
/// own follow-up writes: if the server already applied those side
/// effects atomically we must NOT let the clients re-write stale
/// values.
class CompleteBillResult {
  const CompleteBillResult({required this.bill, required this.rpcSucceeded});

  final Bill bill;
  final bool rpcSucceeded;
}

/// First slice of Sprint 3 #23 (use cases).
///
/// Encapsulates the atomic `complete_bill` Supabase RPC path that used to
/// live inline in `BillProvider.completeBillAsync`. The use case tries
/// the RPC and reports whether it succeeded; the caller owns the
/// fallback save and any peer-provider side effects so that
/// BillProvider's `_enqueueSave` chain (Sprint 1 #21) keeps its
/// serialisation guarantee.
///
/// This slice intentionally does NOT yet pull the cross-provider side
/// effects (stock decrement, credit add, vehicle upsert) out of
/// BillProvider. Later slices will introduce ProductRepository /
/// CustomerRepository dependencies and drain those effects fully.
class CompleteBillUseCase {
  CompleteBillUseCase(this._billRepository);

  final BillRepository _billRepository;

  /// Invokes the atomic `complete_bill` RPC when a [businessId] is
  /// available. Returns a [CompleteBillResult] whose
  /// [CompleteBillResult.rpcSucceeded] flag tells the caller whether
  /// the server already applied stock / credit side effects.
  ///
  /// When [CompleteBillResult.rpcSucceeded] is false the caller MUST
  /// persist [bill] through its own save path so pendingSave
  /// chaining is preserved.
  Future<CompleteBillResult> execute({
    required Bill bill,
    required String? businessId,
    required List<Map<String, dynamic>> stockChanges,
    Map<String, dynamic>? credit,
    required String billPrefix,
  }) async {
    if (businessId == null) {
      return CompleteBillResult(bill: bill, rpcSucceeded: false);
    }
    try {
      await _billRepository.completeBillRpc(
        businessId: businessId,
        bill: bill.toJson(),
        stockChanges: stockChanges,
        credit: credit,
        prefix: billPrefix,
        // Caller already generated a bill number client-side.
        useServerBillNumber: false,
      );
      return CompleteBillResult(bill: bill, rpcSucceeded: true);
    } catch (_) {
      // Offline or RPC error — caller will fall back to a local save.
      return CompleteBillResult(bill: bill, rpcSucceeded: false);
    }
  }
}
