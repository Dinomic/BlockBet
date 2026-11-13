import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/usecases/get_wallets.dart';

part 'wallets_event.dart';
part 'wallets_state.dart';

class WalletsBloc extends Bloc<WalletsEvent, WalletsState> {
  WalletsBloc({required GetWallets getWallets})
      // ignore: prefer_initializing_formals
      : _getWallets = getWallets,
        super(const WalletsState()) {
    on<WalletsRequested>(_onRequested);
  }

  final GetWallets _getWallets;

  Future<void> _onRequested(WalletsRequested event, Emitter<WalletsState> emit) async {
    // Pull-to-refresh keeps the current list on screen; first load shows a skeleton.
    emit(state.copyWith(
      status: state.wallets.isEmpty ? WalletsStatus.loading : state.status,
      isRefreshing: state.wallets.isNotEmpty,
      clearError: true,
    ));
    final result = await _getWallets(const NoParams());
    emit(result.when(
      success: (wallets) => state.copyWith(
        status: WalletsStatus.loaded,
        wallets: wallets,
        isRefreshing: false,
      ),
      failure: (f) => state.wallets.isEmpty
          ? state.copyWith(status: WalletsStatus.failure, errorMessage: f.message, isRefreshing: false)
          // Keep stale data visible; surface the error inline.
          : state.copyWith(errorMessage: f.message, isRefreshing: false),
    ));
  }
}
