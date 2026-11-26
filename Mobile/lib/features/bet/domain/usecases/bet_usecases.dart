import 'package:equatable/equatable.dart';

import '../../../../core/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/bet.dart';
import '../entities/betting_log.dart';
import '../repositories/bet_repository.dart';

class GetBets implements UseCase<BetsPage, GetBetsParams> {
  const GetBets(this._repository);
  final BetRepository _repository;

  @override
  Future<Result<BetsPage>> call(GetBetsParams params) =>
      _repository.getBets(offset: params.offset, limit: params.limit);
}

class GetBetsParams extends Equatable {
  const GetBetsParams({required this.offset, required this.limit});
  final int offset;
  final int limit;

  @override
  List<Object?> get props => [offset, limit];
}

class GetBettingLogs implements UseCase<BettingLogsPage, GetBetsParams> {
  const GetBettingLogs(this._repository);
  final BetRepository _repository;

  @override
  Future<Result<BettingLogsPage>> call(GetBetsParams params) =>
      _repository.getBettingLogs(offset: params.offset, limit: params.limit);
}

class GetBet implements UseCase<Bet, int> {
  const GetBet(this._repository);
  final BetRepository _repository;

  @override
  Future<Result<Bet>> call(int betId) => _repository.getBet(betId);
}

class PlaceBet implements UseCase<String, PlaceBetParams> {
  const PlaceBet(this._repository);
  final BetRepository _repository;

  @override
  Future<Result<String>> call(PlaceBetParams params) => _repository.placeBet(
        betId: params.betId,
        fromAddress: params.fromAddress,
        option: params.option,
      );
}

class PlaceBetParams extends Equatable {
  const PlaceBetParams({required this.betId, required this.fromAddress, required this.option});
  final int betId;
  final String fromAddress;
  final String option;

  @override
  List<Object?> get props => [betId, fromAddress, option];
}

class CreateBet implements UseCase<int, NewBet> {
  const CreateBet(this._repository);
  final BetRepository _repository;

  @override
  Future<Result<int>> call(NewBet params) => _repository.createBet(params);
}

class ResolveBet implements UseCase<String, ResolveBetParams> {
  const ResolveBet(this._repository);
  final BetRepository _repository;

  @override
  Future<Result<String>> call(ResolveBetParams params) =>
      _repository.resolveBet(betId: params.betId, winner: params.winner);
}

class ResolveBetParams extends Equatable {
  const ResolveBetParams({required this.betId, required this.winner});
  final int betId;
  final String winner;

  @override
  List<Object?> get props => [betId, winner];
}
