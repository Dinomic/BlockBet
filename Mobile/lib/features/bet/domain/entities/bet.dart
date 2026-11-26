import 'package:equatable/equatable.dart';

/// Where a bet stands (mirrors the backend `BetStatus`).
enum BetStatus {
  /// Bets are accepted.
  open('Open'),

  /// Betting time is over, waiting for the bookie's result.
  closed('Closed'),
  resolved('Resolved'),

  /// The internal team gave every stake back.
  refunded('Refunded'),

  /// The bookie has not resolved for too long; the internal team handles it.
  caution('Needs attention'),
  unknown('Unknown');

  const BetStatus(this.label);
  final String label;
}

/// One option of a bet. [letter] is what the API uses (A is the first option).
class BetOption extends Equatable {
  const BetOption({required this.letter, required this.name, required this.bettors});

  final String letter;
  final String name;

  /// Number of wallets that bet on this option.
  final int bettors;

  @override
  List<Object?> get props => [letter, name, bettors];
}

class Bet extends Equatable {
  const Bet({
    required this.id,
    required this.title,
    required this.bookieAddress,
    required this.options,
    required this.stake,
    required this.pool,
    required this.status,
    this.description,
    this.imageUrl,
    this.closeTime,
    this.winner,
    this.createdAt,
  });

  final int id;
  final String title;
  final String? description;
  final String? imageUrl;

  /// Wallet of the bookie that created the bet; only that wallet can resolve it.
  final String bookieAddress;
  final List<BetOption> options;

  /// Wei each bettor sends to bet.
  final BigInt stake;

  /// Wei staked in total.
  final BigInt pool;
  final BetStatus status;
  final DateTime? closeTime;

  /// Letter of the winning option, once resolved.
  final String? winner;
  final DateTime? createdAt;

  int get bettors => options.fold(0, (sum, o) => sum + o.bettors);

  BetOption? get winningOption {
    for (final o in options) {
      if (o.letter == winner) return o;
    }
    return null;
  }

  /// The bookie can still pick a result: betting is over and nobody resolved or refunded it.
  bool get awaitsResult => status == BetStatus.closed || status == BetStatus.caution;

  /// True when [addresses] (the signed-in account's wallets, lower-case) hold the bookie wallet.
  bool isCreatedBy(Set<String> addresses) => addresses.contains(bookieAddress.toLowerCase());

  @override
  List<Object?> get props => [
        id, title, description, imageUrl, bookieAddress, options, stake, pool, status, closeTime, winner,
        createdAt,
      ];
}

/// One page of the bet list, newest first.
class BetsPage extends Equatable {
  const BetsPage({required this.offset, required this.total, required this.bets});

  final int offset;

  /// Number of bets on the server, across all pages.
  final int total;
  final List<Bet> bets;

  @override
  List<Object?> get props => [offset, total, bets];
}

/// What a bookie fills in to create a bet.
class NewBet extends Equatable {
  const NewBet({
    required this.fromAddress,
    required this.title,
    required this.options,
    required this.stakeWei,
    required this.duration,
    this.description,
    this.imageUrl,
  });

  final String fromAddress;
  final String title;
  final String? description;
  final String? imageUrl;
  final List<String> options;
  final BigInt stakeWei;
  final Duration duration;

  @override
  List<Object?> get props => [fromAddress, title, description, imageUrl, options, stakeWei, duration];
}
