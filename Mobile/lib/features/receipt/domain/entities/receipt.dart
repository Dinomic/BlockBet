import 'package:equatable/equatable.dart';

enum ReceiptType { funding, tokenTransfer, unknown }

/// Where a transaction stands on the chain.
enum ReceiptStatus { pending, confirmed, failed }

/// One on-chain transaction sent from or to one of the account's wallets.
class Receipt extends Equatable {
  const Receipt({
    required this.hash,
    required this.fromAddress,
    required this.toAddress,
    required this.type,
    required this.success,
    this.blockHash,
    this.blockNumber,
    this.gasUsed,
    this.effectiveGasPrice,
  });

  final String hash;
  final String fromAddress;
  final String toAddress;
  final ReceiptType type;

  /// null = broadcast but not confirmed yet, true = confirmed, false = failed.
  final bool? success;

  final String? blockHash;
  final BigInt? blockNumber;
  final BigInt? gasUsed;
  final BigInt? effectiveGasPrice;

  ReceiptStatus get status => switch (success) {
        null => ReceiptStatus.pending,
        true => ReceiptStatus.confirmed,
        false => ReceiptStatus.failed,
      };

  /// Network fee in wei, known once the transaction is mined.
  BigInt? get feeWei =>
      gasUsed == null || effectiveGasPrice == null ? null : gasUsed! * effectiveGasPrice!;

  @override
  List<Object?> get props =>
      [hash, fromAddress, toAddress, type, success, blockHash, blockNumber, gasUsed, effectiveGasPrice];
}

/// One page of the receipt list, newest first.
class ReceiptsPage extends Equatable {
  const ReceiptsPage({required this.offset, required this.total, required this.receipts});

  final int offset;

  /// Number of receipts on the server, across all pages.
  final int total;
  final List<Receipt> receipts;

  @override
  List<Object?> get props => [offset, total, receipts];
}
