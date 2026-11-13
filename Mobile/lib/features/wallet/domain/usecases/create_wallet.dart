import '../../../../core/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class CreateWallet implements UseCase<Wallet, String> {
  const CreateWallet(this._repository);
  final WalletRepository _repository;

  @override
  Future<Result<Wallet>> call(String password) => _repository.createWallet(password);
}
