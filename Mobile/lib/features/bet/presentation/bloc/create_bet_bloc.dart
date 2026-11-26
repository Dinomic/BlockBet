import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/bet.dart';
import '../../domain/usecases/bet_usecases.dart';

enum CreateBetStatus { idle, submitting, success, failure }

class CreateBetState extends Equatable {
  const CreateBetState({this.status = CreateBetStatus.idle, this.betId, this.errorMessage});

  final CreateBetStatus status;
  final int? betId;
  final String? errorMessage;

  bool get isSubmitting => status == CreateBetStatus.submitting;

  @override
  List<Object?> get props => [status, betId, errorMessage];
}

sealed class CreateBetEvent extends Equatable {
  const CreateBetEvent();
  @override
  List<Object?> get props => [];
}

class CreateBetSubmitted extends CreateBetEvent {
  const CreateBetSubmitted(this.bet);
  final NewBet bet;

  @override
  List<Object?> get props => [bet];
}

/// Clears a previous error, e.g. when the user edits the form again.
class CreateBetErrorDismissed extends CreateBetEvent {
  const CreateBetErrorDismissed();
}

class CreateBetBloc extends Bloc<CreateBetEvent, CreateBetState> {
  CreateBetBloc({required CreateBet createBet})
      // ignore: prefer_initializing_formals
      : _createBet = createBet,
        super(const CreateBetState()) {
    on<CreateBetSubmitted>(_onSubmitted);
    on<CreateBetErrorDismissed>((_, emit) => emit(const CreateBetState()));
  }

  final CreateBet _createBet;

  Future<void> _onSubmitted(CreateBetSubmitted event, Emitter<CreateBetState> emit) async {
    // Ignore double taps: a second request would create a second bet.
    if (state.isSubmitting || state.status == CreateBetStatus.success) return;
    emit(const CreateBetState(status: CreateBetStatus.submitting));
    final result = await _createBet(event.bet);
    emit(result.when(
      success: (id) => CreateBetState(status: CreateBetStatus.success, betId: id),
      failure: (f) => CreateBetState(status: CreateBetStatus.failure, errorMessage: f.message),
    ));
  }
}
