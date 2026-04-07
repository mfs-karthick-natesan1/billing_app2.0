import '../../models/bill.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../repositories/bill_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/product_repository.dart';

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
  CompleteBillUseCase(
    this._billRepository, {
    ProductRepository? productRepository,
    CustomerRepository? customerRepository,
  })  : _productRepository = productRepository,
        _customerRepository = customerRepository;

  final BillRepository _billRepository;
  // Sprint 3 #23 slice 4: optional peer repositories so the use case can
  // persist the fallback-path stock/credit side effects directly, without
  // BillProvider having to ask ProductProvider / CustomerProvider to do
  // their own database writes.
  final ProductRepository? _productRepository;
  final CustomerRepository? _customerRepository;

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

  /// Persists the fallback-path stock and credit side effects after
  /// [execute] returned `rpcSucceeded: false`. Pass the already-updated
  /// [Product] snapshots (i.e. stock after the decrement is applied in
  /// memory) and, if relevant, the [Customer] with the new outstanding
  /// balance. BillProvider still owns the in-memory cache update via
  /// ProductProvider / CustomerProvider; this method just writes the
  /// snapshots through the repository layer so the cross-provider
  /// persistence path is centralised here rather than scattered across
  /// `persist: true` calls on peer providers.
  Future<void> persistFallbackSideEffects({
    List<Product> updatedProducts = const [],
    Customer? updatedCustomer,
  }) async {
    final productRepo = _productRepository;
    if (productRepo != null && updatedProducts.isNotEmpty) {
      await productRepo.saveAll(updatedProducts);
    }
    final customerRepo = _customerRepository;
    if (customerRepo != null && updatedCustomer != null) {
      await customerRepo.saveAll([updatedCustomer]);
    }
  }
}
