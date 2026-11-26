import '../../../../core/result.dart';
import '../entities/bet.dart';
import '../entities/betting_log.dart';

abstract class BetRepository {
  Future<Result<BetsPage>> getBets({required int offset, required int limit});

  Future<Result<Bet>> getBet(int betId);

  /// The caller's own betting actions, newest first.
  Future<Result<BettingLogsPage>> getBettingLogs({required int offset, required int limit});

  /// Bettor: bet on [option] (a letter, `A`..`E`) paying the bet's stake from [fromAddress]. Returns the tx hash.
  Future<Result<String>> placeBet({required int betId, required String fromAddress, required String option});

  /// Bookie: create a bet. Returns the new bet's id.
  Future<Result<int>> createBet(NewBet bet);

  /// Bookie: pick the winning option ([winner] is a letter). Returns the tx hash.
  Future<Result<String>> resolveBet({required int betId, required String winner});
}
