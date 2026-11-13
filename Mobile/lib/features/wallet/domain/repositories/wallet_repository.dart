import '../../../../core/result.dart';
import '../entities/wallet.dart';

abstract class WalletRepository {
  Future<Result<List<Wallet>>> getWallets();

  /// Creates a wallet protected by [password]. The returned wallet has a zero balance
  /// until the list is reloaded.
  Future<Result<Wallet>> createWallet(String password);
}
