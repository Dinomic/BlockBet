part of 'receipts_bloc.dart';

sealed class ReceiptsEvent extends Equatable {
  const ReceiptsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads (or reloads) the first page of receipts.
class ReceiptsRequested extends ReceiptsEvent {
  const ReceiptsRequested();
}

/// Appends the next page when the list is scrolled near its end.
class ReceiptsMoreRequested extends ReceiptsEvent {
  const ReceiptsMoreRequested();
}
