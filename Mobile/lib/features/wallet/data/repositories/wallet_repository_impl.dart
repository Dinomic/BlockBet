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
  Future<Result<List<Wallet>>> getWallets() async {
    try {
      return Success(await remote.getWallets());
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
