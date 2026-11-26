import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bet.dart';
import '../../domain/usecases/bet_usecases.dart';

enum BetsStatus { loading, loaded, failure }

class BetsState extends Equatable {
  const BetsState({
    this.status = BetsStatus.loading,
    this.bets = const [],
    this.total = 0,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final BetsStatus status;
  final List<Bet> bets;

  /// Number of bets on the server, across all pages.
  final int total;
  final bool isRefreshing;
  final bool isLoadingMore;

  /// Last load error. With stale data on screen it is shown inline.
  final String? errorMessage;

  bool get hasMore => bets.length < total;

  BetsState copyWith({
    BetsStatus? status,
    List<Bet>? bets,
    int? total,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BetsState(
      status: status ?? this.status,
      bets: bets ?? this.bets,
      total: total ?? this.total,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, bets, total, isRefreshing, isLoadingMore, errorMessage];
}

sealed class BetsEvent extends Equatable {
  const BetsEvent();
  @override
  List<Object?> get props => [];
}

class BetsRequested extends BetsEvent {
  const BetsRequested();
}

class BetsMoreRequested extends BetsEvent {
  const BetsMoreRequested();
}

class BetsBloc extends Bloc<BetsEvent, BetsState> {
  BetsBloc({required GetBets getBets})
      // ignore: prefer_initializing_formals
      : _getBets = getBets,
        super(const BetsState()) {
    on<BetsRequested>(_onRequested);
    on<BetsMoreRequested>(_onMoreRequested);
  }

  static const pageSize = 20;

  final GetBets _getBets;

  Future<void> _onRequested(BetsRequested event, Emitter<BetsState> emit) async {
    // Pull-to-refresh keeps the current list on screen; first load shows a skeleton.
    emit(state.copyWith(
      status: state.bets.isEmpty ? BetsStatus.loading : state.status,
      isRefreshing: state.bets.isNotEmpty,
      clearError: true,
    ));
    final result = await _getBets(const GetBetsParams(offset: 0, limit: pageSize));
    emit(result.when(
      success: (page) => state.copyWith(
        status: BetsStatus.loaded,
        bets: page.bets,
        total: page.total,
        isRefreshing: false,
        isLoadingMore: false,
      ),
      failure: (f) => state.bets.isEmpty
          ? state.copyWith(status: BetsStatus.failure, errorMessage: f.message, isRefreshing: false)
          : state.copyWith(errorMessage: f.message, isRefreshing: false),
    ));
  }

  Future<void> _onMoreRequested(BetsMoreRequested event, Emitter<BetsState> emit) async {
    if (state.status != BetsStatus.loaded || state.isLoadingMore || state.isRefreshing || !state.hasMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    final result = await _getBets(GetBetsParams(offset: state.bets.length, limit: pageSize));
    emit(result.when(
      success: (page) {
        // New bets shift the offsets, so a page can overlap the list: skip repeats.
        final known = {for (final b in state.bets) b.id};
        final fresh = page.bets.where((b) => !known.contains(b.id));
        return state.copyWith(bets: [...state.bets, ...fresh], total: page.total, isLoadingMore: false);
      },
      failure: (f) => state.copyWith(isLoadingMore: false, errorMessage: f.message),
    ));
  }
}
