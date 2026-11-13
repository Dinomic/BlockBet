import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/transfer_tokens.dart';

enum TransferStatus { idle, submitting, success, failure }

class TransferState extends Equatable {
  const TransferState({this.status = TransferStatus.idle, this.txHash, this.errorMessage});

  final TransferStatus status;
  final String? txHash;
  final String? errorMessage;

  bool get isSubmitting => status == TransferStatus.submitting;

  @override
  List<Object?> get props => [status, txHash, errorMessage];
}

sealed class TransferEvent extends Equatable {
  const TransferEvent();
  @override
  List<Object?> get props => [];
}

class TransferSubmitted extends TransferEvent {
  const TransferSubmitted(this.params);
  final TransferParams params;

  @override
  List<Object?> get props => [params];
}

/// Clears a previous error, e.g. when the user edits the form again.
class TransferErrorDismissed extends TransferEvent {
  const TransferErrorDismissed();
}

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc({required TransferTokens transferTokens})
      // ignore: prefer_initializing_formals
      : _transferTokens = transferTokens,
        super(const TransferState()) {
    on<TransferSubmitted>(_onSubmitted);
    on<TransferErrorDismissed>((_, emit) => emit(const TransferState()));
  }

  final TransferTokens _transferTokens;

  Future<void> _onSubmitted(TransferSubmitted event, Emitter<TransferState> emit) async {
    // Ignore double taps: a second request would send the funds twice.
    if (state.isSubmitting || state.status == TransferStatus.success) return;
    emit(const TransferState(status: TransferStatus.submitting));
    final result = await _transferTokens(event.params);
    emit(result.when(
      success: (hash) => TransferState(status: TransferStatus.success, txHash: hash),
      failure: (f) => TransferState(status: TransferStatus.failure, errorMessage: f.message),
    ));
  }
}
