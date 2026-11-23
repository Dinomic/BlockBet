import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../datasources/receipt_remote_data_source.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  ReceiptRepositoryImpl({required this.remote});
  final ReceiptRemoteDataSource remote;

  @override
  Future<Result<ReceiptsPage>> getReceipts({required int offset, required int limit}) async {
    try {
      return Success(await remote.getReceipts(offset: offset, limit: limit));
    } on ServerException catch (e) {
      final status = e.statusCode;
      if (status == 401 || status == 403) {
        return const Err(ServerFailure('Your session has expired. Log in again.', statusCode: 401));
      }
      if (status != null && status >= 500) return const Err(NetworkFailure());
      return Err(ServerFailure(e.message, statusCode: status));
    } on NetworkException {
      return const Err(NetworkFailure());
    }
  }
}
