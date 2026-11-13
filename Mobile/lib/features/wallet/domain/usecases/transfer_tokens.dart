import 'package:equatable/equatable.dart';

import '../../../../core/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/wallet_repository.dart';

class TransferParams extends Equatable {
  const TransferParams({
    required this.fromAddress,
    required this.toAddress,
    required this.amountWei,
    required this.idempotencyKey,
  });
  final String fromAddress;
  final String toAddress;
  final BigInt amountWei;

  /// Required by the server. Same key = same transfer: it returns the original result instead of
  /// sending again, which makes retrying after a timeout safe.
  final String idempotencyKey;

  @override
  List<Object?> get props => [fromAddress, toAddress, amountWei, idempotencyKey];
}

/// Returns the transaction hash.
class TransferTokens implements UseCase<String, TransferParams> {
  const TransferTokens(this._repository);
  final WalletRepository _repository;

  @override
  Future<Result<String>> call(TransferParams p) => _repository.transferTokens(
        fromAddress: p.fromAddress,
        toAddress: p.toAddress,
        amountWei: p.amountWei,
        idempotencyKey: p.idempotencyKey,
      );
}
