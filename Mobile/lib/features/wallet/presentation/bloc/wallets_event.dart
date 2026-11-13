part of 'wallets_bloc.dart';

sealed class WalletsEvent extends Equatable {
  const WalletsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads (or reloads) the account's wallets and their balances.
class WalletsRequested extends WalletsEvent {
  const WalletsRequested();
}
