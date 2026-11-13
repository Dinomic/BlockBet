part of 'wallets_bloc.dart';

enum WalletsStatus { loading, loaded, failure }

class WalletsState extends Equatable {
  const WalletsState({
    this.status = WalletsStatus.loading,
    this.wallets = const [],
    this.isRefreshing = false,
    this.errorMessage,
    this.isCreating = false,
    this.createError,
    this.createCount = 0,
  });

  final WalletsStatus status;
  final List<Wallet> wallets;
  final bool isRefreshing;
  final String? errorMessage;

  final bool isCreating;

  /// Last create-wallet error (cleared when a new attempt starts).
  final String? createError;

  /// Incremented after every successful create, so the UI can react once per wallet.
  final int createCount;

  bool get limitReached => wallets.length >= Wallet.maxPerAccount;

  /// Sum of all wallet balances, in wei.
  BigInt get totalWei => wallets.fold(BigInt.zero, (sum, w) => sum + w.balanceWei);

  WalletsState copyWith({
    WalletsStatus? status,
    List<Wallet>? wallets,
    bool? isRefreshing,
    String? errorMessage,
    bool clearError = false,
    bool? isCreating,
    String? createError,
    bool clearCreateError = false,
    int? createCount,
  }) {
    return WalletsState(
      status: status ?? this.status,
      wallets: wallets ?? this.wallets,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCreating: isCreating ?? this.isCreating,
      createError: clearCreateError ? null : (createError ?? this.createError),
      createCount: createCount ?? this.createCount,
    );
  }

  @override
  List<Object?> get props =>
      [status, wallets, isRefreshing, errorMessage, isCreating, createError, createCount];
}
