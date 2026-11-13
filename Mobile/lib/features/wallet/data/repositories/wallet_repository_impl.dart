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
