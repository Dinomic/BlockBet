part of 'receipts_bloc.dart';

enum ReceiptsStatus { loading, loaded, failure }

class ReceiptsState extends Equatable {
  const ReceiptsState({
    this.status = ReceiptsStatus.loading,
    this.receipts = const [],
    this.total = 0,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final ReceiptsStatus status;
  final List<Receipt> receipts;

  /// Number of receipts on the server, across all pages.
  final int total;
  final bool isRefreshing;
  final bool isLoadingMore;

  /// Last load error. With stale data on screen it is shown inline.
  final String? errorMessage;

  bool get hasMore => receipts.length < total;

  ReceiptsState copyWith({
    ReceiptsStatus? status,
    List<Receipt>? receipts,
    int? total,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReceiptsState(
      status: status ?? this.status,
      receipts: receipts ?? this.receipts,
      total: total ?? this.total,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, receipts, total, isRefreshing, isLoadingMore, errorMessage];
}
