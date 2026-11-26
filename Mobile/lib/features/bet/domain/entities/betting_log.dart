import 'package:equatable/equatable.dart';

enum BettingAction {
  created('Bet created'),
  placed('Bet placed'),
  resolved('Result picked'),
  refunded('Bet refunded'),
  cautionFlagged('Not resolved in time'),
  unknown('Betting action');

  const BettingAction(this.label);
  final String label;
}

/// One row of the caller's betting log (`GET /bettor/betting-logs`).
class BettingLog extends Equatable {
  const BettingLog({
    required this.id,
    required this.betId,
    required this.action,
    this.walletAddress,
    this.option,
    this.amount,
    this.txHash,
    this.detail,
    this.createdAt,
  });

  final int id;
  final int betId;
  final BettingAction action;
  final String? walletAddress;

  /// Option letter (`A`..`E`) the action is about, when there is one.
  final String? option;

  /// Wei the action moved (the stake of a placed bet).
  final BigInt? amount;
  final String? txHash;
  final String? detail;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, betId, action, walletAddress, option, amount, txHash, detail, createdAt];
}

class BettingLogsPage extends Equatable {
  const BettingLogsPage({required this.offset, required this.total, required this.logs});

  final int offset;

  /// Number of log rows on the server, across all pages.
  final int total;
  final List<BettingLog> logs;

  @override
  List<Object?> get props => [offset, total, logs];
}
