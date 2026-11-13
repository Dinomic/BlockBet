part of 'wallets_bloc.dart';

enum WalletsStatus { loading, loaded, failure }

class WalletsState extends Equatable {
  const WalletsState({
    this.status = WalletsStatus.loading,
    this.wallets = const [],
    this.isRefreshing = false,
    this.errorMessage,
  });

  final WalletsStatus status;
  final List<Wallet> wallets;
  final bool isRefreshing;
  final String? errorMessage;

  /// Sum of all wallet balances, in wei.
  BigInt get totalWei => wallets.fold(BigInt.zero, (sum, w) => sum + w.balanceWei);

  WalletsState copyWith({
    WalletsStatus? status,
    List<Wallet>? wallets,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WalletsState(
      status: status ?? this.status,
      wallets: wallets ?? this.wallets,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, wallets, isRefreshing, errorMessage];
}
