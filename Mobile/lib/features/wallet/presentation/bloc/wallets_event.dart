part of 'wallets_bloc.dart';

sealed class WalletsEvent extends Equatable {
  const WalletsEvent();

  @override
  List<Object?> get props => [];
}

/// Creates a new wallet protected by [password], then reloads the list.
class WalletCreated extends WalletsEvent {
  const WalletCreated(this.password);
  final String password;

  @override
  List<Object?> get props => [password];
}

/// Loads (or reloads) the account's wallets and their balances.
class WalletsRequested extends WalletsEvent {
  const WalletsRequested();
}
