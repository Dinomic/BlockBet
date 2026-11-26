import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/result.dart';
import '../../domain/entities/bet.dart';
import '../../domain/entities/betting_log.dart';
import '../../domain/repositories/bet_repository.dart';
import '../datasources/bet_remote_data_source.dart';

class BetRepositoryImpl implements BetRepository {
  BetRepositoryImpl({required this.remote});
  final BetRemoteDataSource remote;

  @override
  Future<Result<BetsPage>> getBets({required int offset, required int limit}) =>
      _read(() => remote.getBets(offset: offset, limit: limit));

  @override
  Future<Result<Bet>> getBet(int betId) => _read(() => remote.getBet(betId));

  @override
  Future<Result<BettingLogsPage>> getBettingLogs({required int offset, required int limit}) =>
      _read(() => remote.getBettingLogs(offset: offset, limit: limit));

  @override
  Future<Result<String>> placeBet({required int betId, required String fromAddress, required String option}) =>
      _write(() => remote.placeBet(betId: betId, fromAddress: fromAddress, option: option));

  @override
  Future<Result<int>> createBet(NewBet bet) => _write(() => remote.createBet(bet));

  @override
  Future<Result<String>> resolveBet({required int betId, required String winner}) =>
      _write(() => remote.resolveBet(betId: betId, winner: winner));

  Future<Result<T>> _read<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on ServerException catch (e) {
      return Err(_serverFailure(e));
    } on NetworkException {
      return const Err(NetworkFailure());
    }
  }

  /// A write is sent to the chain: if the answer is lost the action may still have happened, so the
  /// message tells the user to check before trying again.
  Future<Result<T>> _write<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } on ServerException catch (e) {
      final status = e.statusCode;
      if (status != null && status >= 500) {
        return const Err(ServerFailure(
          "The network couldn't process this request. Open the bet to see if it went through, then try again.",
        ));
      }
      return Err(_serverFailure(e));
    } on NetworkException {
      return const Err(NetworkFailure(
        "We couldn't confirm the result. It may still have gone through: check the bet before trying again.",
      ));
    }
  }

  Failure _serverFailure(ServerException e) {
    final status = e.statusCode;
    if (status == 401) return const ServerFailure('Your session has expired. Log in again.', statusCode: 401);
    if (status == 403) {
      return const ServerFailure("Your account's role doesn't allow this action.", statusCode: 403);
    }
    if (status != null && status >= 500) return const NetworkFailure();
    // 4xx messages (bet closed, already bet, wallet not found, ...) are written for the user.
    return ServerFailure(e.message, statusCode: status);
  }
}
