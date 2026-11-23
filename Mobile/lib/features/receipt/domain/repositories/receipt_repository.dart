import '../../../../core/result.dart';
import '../entities/receipt.dart';

abstract class ReceiptRepository {
  /// Loads [limit] receipts starting at [offset], newest first.
  Future<Result<ReceiptsPage>> getReceipts({required int offset, required int limit});
}
