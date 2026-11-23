import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/receipt.dart';
import '../../domain/usecases/get_receipts.dart';

part 'receipts_event.dart';
part 'receipts_state.dart';

class ReceiptsBloc extends Bloc<ReceiptsEvent, ReceiptsState> {
  ReceiptsBloc({required GetReceipts getReceipts})
      // ignore: prefer_initializing_formals
      : _getReceipts = getReceipts,
        super(const ReceiptsState()) {
    on<ReceiptsRequested>(_onRequested);
    on<ReceiptsMoreRequested>(_onMoreRequested);
  }

  static const pageSize = 20;

  final GetReceipts _getReceipts;

  Future<void> _onRequested(ReceiptsRequested event, Emitter<ReceiptsState> emit) async {
    // Pull-to-refresh keeps the current list on screen; first load shows a skeleton.
    emit(state.copyWith(
      status: state.receipts.isEmpty ? ReceiptsStatus.loading : state.status,
      isRefreshing: state.receipts.isNotEmpty,
      clearError: true,
    ));
    final result = await _getReceipts(const GetReceiptsParams(offset: 0, limit: pageSize));
    emit(result.when(
      success: (page) => state.copyWith(
        status: ReceiptsStatus.loaded,
        receipts: page.receipts,
        total: page.total,
        isRefreshing: false,
        isLoadingMore: false,
      ),
      failure: (f) => state.receipts.isEmpty
          ? state.copyWith(status: ReceiptsStatus.failure, errorMessage: f.message, isRefreshing: false)
          // Keep stale data visible; surface the error inline.
          : state.copyWith(errorMessage: f.message, isRefreshing: false),
    ));
  }

  Future<void> _onMoreRequested(ReceiptsMoreRequested event, Emitter<ReceiptsState> emit) async {
    if (state.status != ReceiptsStatus.loaded ||
        state.isLoadingMore ||
        state.isRefreshing ||
        !state.hasMore) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    final result = await _getReceipts(
      GetReceiptsParams(offset: state.receipts.length, limit: pageSize),
    );
    emit(result.when(
      success: (page) {
        // New transactions shift the offsets, so a page can overlap the list: skip repeats.
        final known = {for (final r in state.receipts) r.hash};
        final fresh = page.receipts.where((r) => !known.contains(r.hash));
        return state.copyWith(
          receipts: [...state.receipts, ...fresh],
          total: page.total,
          isLoadingMore: false,
        );
      },
      failure: (f) => state.copyWith(isLoadingMore: false, errorMessage: f.message),
    ));
  }
}
