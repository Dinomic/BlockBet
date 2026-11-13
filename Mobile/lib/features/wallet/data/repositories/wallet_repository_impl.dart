import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl({required this.remote});
  final WalletRemoteDataSource remote;

  @override
  Future<Result<List<Wallet>>> getWallets() => _run(remote.getWallets);

  @override
  Future<Result<Wallet>> createWallet(String password) => _run(() => remote.createWallet(password));

  @override
  Future<Result<String>> transferTokens({
    required String fromAddress,
    required String toAddress,
    required BigInt amountWei,
    required String idempotencyKey,
  }) async {
    try {
      return Success(await remote.transferTokens(
        fromAddress: fromAddress,
        toAddress: toAddress,
        amountWei: amountWei,
        idempotencyKey: idempotencyKey,
      ));
    } on ServerException catch (e) {
      final status = e.statusCode;
      if (status == 401 || status == 403) {
        return const Err(ServerFailure('Your session has expired. Log in again.', statusCode: 401));
      }
      if (status != null && status >= 500) {
        return const Err(ServerFailure(
          "The network couldn't process this transfer. Check your wallet balances, then try again.",
        ));
      }
      // 4xx messages (invalid address, insufficient balance, ...) are written for the user.
      return Err(ServerFailure(e.message, statusCode: status));
    } on NetworkException {
      // The request may have reached the server. Retrying is safe: the app reuses the same
      // idempotency key, so the server returns the original transfer instead of sending twice.
      return const Err(NetworkFailure(
        "We couldn't confirm the transfer. Tap Review transfer to try again — it won't be sent twice.",
      ));
    }
  }

  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on ServerException catch (e) {
      final status = e.statusCode;
      if (status == 401 || status == 403) {
        return const Err(ServerFailure('Your session has expired. Log in again.', statusCode: 401));
      }
      // Business rule (e.g. wallet limit): the server message is meant for the user.
      if (status == 409) return Err(ServerFailure(e.message, statusCode: status));
      if (status != null && status >= 500) return const Err(NetworkFailure());
      return Err(ServerFailure(e.message, statusCode: status));
    } on NetworkException {
      return const Err(NetworkFailure());
    }
  }
}
