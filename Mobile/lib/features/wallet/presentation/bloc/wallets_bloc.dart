import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/usecases/create_wallet.dart';
import '../../domain/usecases/get_wallets.dart';

part 'wallets_event.dart';
part 'wallets_state.dart';

class WalletsBloc extends Bloc<WalletsEvent, WalletsState> {
  WalletsBloc({required GetWallets getWallets, required CreateWallet createWallet})
      // ignore: prefer_initializing_formals
      : _getWallets = getWallets,
        // ignore: prefer_initializing_formals
        _createWallet = createWallet,
        super(const WalletsState()) {
    on<WalletsRequested>(_onRequested);
    on<WalletCreated>(_onCreated);
  }

  final GetWallets _getWallets;
  final CreateWallet _createWallet;

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

  Future<void> _onCreated(WalletCreated event, Emitter<WalletsState> emit) async {
    if (state.isCreating) return;
    if (state.wallets.length >= Wallet.maxPerAccount) {
      emit(state.copyWith(
        createError: 'You can have at most ${Wallet.maxPerAccount} wallets per account.',
      ));
      return;
    }
    emit(state.copyWith(isCreating: true, clearCreateError: true));
    final countBefore = state.wallets.length;
    final result = await _createWallet(event.password);
    final failure = result.when<Failure?>(success: (_) => null, failure: (f) => f);

    // A network-level failure is ambiguous for this call: the server may have created
    // (and funded) the wallet but answered too slowly. Check the list before reporting failure.
    final ambiguous = failure is NetworkFailure;
    if (failure != null && !ambiguous) {
      emit(state.copyWith(isCreating: false, createError: failure.message));
      return;
    }

    final reload = await _getWallets(const NoParams());
    emit(reload.when(
      success: (wallets) {
        final created = failure == null || wallets.length > countBefore;
        return state.copyWith(
          status: WalletsStatus.loaded,
          wallets: wallets,
          isCreating: false,
          createCount: created ? state.createCount + 1 : null,
          createError: created ? null : failure.message,
        );
      },
      failure: (_) => failure == null
          // Created but the refresh failed: still a success for the user.
          ? state.copyWith(isCreating: false, createCount: state.createCount + 1)
          : state.copyWith(
              isCreating: false,
              createError: "Couldn't confirm the new wallet. Pull down to refresh the list.",
            ),
    ));
  }
}
