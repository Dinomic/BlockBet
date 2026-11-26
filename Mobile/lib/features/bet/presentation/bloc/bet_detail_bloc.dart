import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bet.dart';
import '../../domain/usecases/bet_usecases.dart';

enum BetDetailStatus { loading, loaded, failure }

class BetDetailState extends Equatable {
  const BetDetailState({
    this.status = BetDetailStatus.loading,
    this.bet,
    this.errorMessage,
    this.isActing = false,
    this.actionError,
    this.doneCount = 0,
    this.doneMessage,
  });

  final BetDetailStatus status;
  final Bet? bet;

  /// Why the bet could not be loaded.
  final String? errorMessage;

  /// A place-bet / resolve request is in flight (they wait until the chain mined the transaction).
  final bool isActing;
  final String? actionError;

  /// Incremented after every successful action so the UI can react once per action.
  final int doneCount;
  final String? doneMessage;

  BetDetailState copyWith({
    BetDetailStatus? status,
    Bet? bet,
    String? errorMessage,
    bool clearError = false,
    bool? isActing,
    String? actionError,
    bool clearActionError = false,
    int? doneCount,
    String? doneMessage,
  }) {
    return BetDetailState(
      status: status ?? this.status,
      bet: bet ?? this.bet,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isActing: isActing ?? this.isActing,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
      doneCount: doneCount ?? this.doneCount,
      doneMessage: doneMessage ?? this.doneMessage,
    );
  }

  @override
  List<Object?> get props => [status, bet, errorMessage, isActing, actionError, doneCount, doneMessage];
}

sealed class BetDetailEvent extends Equatable {
  const BetDetailEvent();
  @override
  List<Object?> get props => [];
}

class BetDetailRequested extends BetDetailEvent {
  const BetDetailRequested();
}

/// Bettor: bet on [option] with the wallet at [fromAddress].
class BetPlaced extends BetDetailEvent {
  const BetPlaced({required this.option, required this.fromAddress});
  final String option;
  final String fromAddress;

  @override
  List<Object?> get props => [option, fromAddress];
}

/// Bookie: pick [winner] as the winning option.
class BetResolved extends BetDetailEvent {
  const BetResolved(this.winner);
  final String winner;

  @override
  List<Object?> get props => [winner];
}

class BetDetailBloc extends Bloc<BetDetailEvent, BetDetailState> {
  BetDetailBloc({
    required this.betId,
    required GetBet getBet,
    required PlaceBet placeBet,
    required ResolveBet resolveBet,
  })
      // ignore: prefer_initializing_formals
      : _getBet = getBet,
        // ignore: prefer_initializing_formals
        _placeBet = placeBet,
        // ignore: prefer_initializing_formals
        _resolveBet = resolveBet,
        super(const BetDetailState()) {
    on<BetDetailRequested>(_onRequested);
    on<BetPlaced>(_onPlaced);
    on<BetResolved>(_onResolved);
  }

  final int betId;
  final GetBet _getBet;
  final PlaceBet _placeBet;
  final ResolveBet _resolveBet;

  Future<void> _onRequested(BetDetailRequested event, Emitter<BetDetailState> emit) async {
    if (state.bet == null) emit(state.copyWith(status: BetDetailStatus.loading, clearError: true));
    final result = await _getBet(betId);
    emit(result.when(
      success: (bet) => state.copyWith(status: BetDetailStatus.loaded, bet: bet, clearError: true),
      failure: (f) => state.bet == null
          ? state.copyWith(status: BetDetailStatus.failure, errorMessage: f.message)
          // Keep the last known bet on screen.
          : state.copyWith(errorMessage: f.message),
    ));
  }

  Future<void> _onPlaced(BetPlaced event, Emitter<BetDetailState> emit) async {
    // Ignore double taps: a second request would be rejected or, worse, race the first.
    if (state.isActing) return;
    emit(state.copyWith(isActing: true, clearActionError: true));
    final result = await _placeBet(
      PlaceBetParams(betId: betId, fromAddress: event.fromAddress, option: event.option),
    );
    await _finish(emit, result.when(success: (_) => null, failure: (f) => f.message), 'Your bet is placed.');
  }

  Future<void> _onResolved(BetResolved event, Emitter<BetDetailState> emit) async {
    if (state.isActing) return;
    emit(state.copyWith(isActing: true, clearActionError: true));
    final result = await _resolveBet(ResolveBetParams(betId: betId, winner: event.winner));
    await _finish(emit, result.when(success: (_) => null, failure: (f) => f.message),
        'Result saved. The pool has been paid out.');
  }

  /// Reloads the bet after an action (also after a failure: a lost answer may still have changed it).
  Future<void> _finish(Emitter<BetDetailState> emit, String? error, String doneMessage) async {
    final reload = await _getBet(betId);
    final bet = reload.when<Bet?>(success: (b) => b, failure: (_) => null);
    emit(state.copyWith(
      isActing: false,
      bet: bet,
      actionError: error,
      doneCount: error == null ? state.doneCount + 1 : null,
      doneMessage: error == null ? doneMessage : null,
    ));
  }
}
