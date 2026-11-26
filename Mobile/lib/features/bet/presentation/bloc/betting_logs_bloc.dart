import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/betting_log.dart';
import '../../domain/usecases/bet_usecases.dart';

enum BettingLogsStatus { loading, loaded, failure }

class BettingLogsState extends Equatable {
  const BettingLogsState({
    this.status = BettingLogsStatus.loading,
    this.logs = const [],
    this.total = 0,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final BettingLogsStatus status;
  final List<BettingLog> logs;

  /// Number of log rows on the server, across all pages.
  final int total;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get hasMore => logs.length < total;

  BettingLogsState copyWith({
    BettingLogsStatus? status,
    List<BettingLog>? logs,
    int? total,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BettingLogsState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      total: total ?? this.total,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, logs, total, isRefreshing, isLoadingMore, errorMessage];
}

sealed class BettingLogsEvent extends Equatable {
  const BettingLogsEvent();
  @override
  List<Object?> get props => [];
}

class BettingLogsRequested extends BettingLogsEvent {
  const BettingLogsRequested();
}

class BettingLogsMoreRequested extends BettingLogsEvent {
  const BettingLogsMoreRequested();
}

class BettingLogsBloc extends Bloc<BettingLogsEvent, BettingLogsState> {
  BettingLogsBloc({required GetBettingLogs getLogs})
      // ignore: prefer_initializing_formals
      : _getLogs = getLogs,
        super(const BettingLogsState()) {
    on<BettingLogsRequested>(_onRequested);
    on<BettingLogsMoreRequested>(_onMoreRequested);
  }

  static const pageSize = 20;

  final GetBettingLogs _getLogs;

  Future<void> _onRequested(BettingLogsRequested event, Emitter<BettingLogsState> emit) async {
    emit(state.copyWith(
      status: state.logs.isEmpty ? BettingLogsStatus.loading : state.status,
      isRefreshing: state.logs.isNotEmpty,
      clearError: true,
    ));
    final result = await _getLogs(const GetBetsParams(offset: 0, limit: pageSize));
    emit(result.when(
      success: (page) => state.copyWith(
        status: BettingLogsStatus.loaded,
        logs: page.logs,
        total: page.total,
        isRefreshing: false,
        isLoadingMore: false,
      ),
      failure: (f) => state.logs.isEmpty
          ? state.copyWith(status: BettingLogsStatus.failure, errorMessage: f.message, isRefreshing: false)
          : state.copyWith(errorMessage: f.message, isRefreshing: false),
    ));
  }

  Future<void> _onMoreRequested(BettingLogsMoreRequested event, Emitter<BettingLogsState> emit) async {
    if (state.status != BettingLogsStatus.loaded || state.isLoadingMore || state.isRefreshing || !state.hasMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    final result = await _getLogs(GetBetsParams(offset: state.logs.length, limit: pageSize));
    emit(result.when(
      success: (page) {
        // New rows shift the offsets (newest first), so a page can overlap the list: skip repeats.
        final known = {for (final l in state.logs) l.id};
        final fresh = page.logs.where((l) => !known.contains(l.id));
        return state.copyWith(logs: [...state.logs, ...fresh], total: page.total, isLoadingMore: false);
      },
      failure: (f) => state.copyWith(isLoadingMore: false, errorMessage: f.message),
    ));
  }
}
