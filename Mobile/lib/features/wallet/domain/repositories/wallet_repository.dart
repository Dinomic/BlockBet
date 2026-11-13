import '../../../../core/result.dart';
import '../entities/wallet.dart';

abstract class WalletRepository {
  Future<Result<List<Wallet>>> getWallets();

  /// Creates a wallet protected by [password]. The returned wallet has a zero balance
  /// until the list is reloaded.
  Future<Result<Wallet>> createWallet(String password);

  /// Sends [amountWei] from one of the account's wallets. Returns the transaction hash;
  /// the transfer is only broadcast, so balances change once the network confirms it.
  Future<Result<String>> transferTokens({
    required String fromAddress,
    required String toAddress,
    required BigInt amountWei,
    required String idempotencyKey,
  });
}
