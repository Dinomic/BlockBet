import '../../../../core/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class GetWallets implements UseCase<List<Wallet>, NoParams> {
  const GetWallets(this._repository);
  final WalletRepository _repository;

  @override
  Future<Result<List<Wallet>>> call(NoParams params) => _repository.getWallets();
}
