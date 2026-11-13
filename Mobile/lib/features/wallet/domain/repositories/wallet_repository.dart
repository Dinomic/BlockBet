import '../../../../core/result.dart';
import '../entities/wallet.dart';

abstract class WalletRepository {
  Future<Result<List<Wallet>>> getWallets();
}
