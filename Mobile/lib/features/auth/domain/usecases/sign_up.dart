import 'package:equatable/equatable.dart';

import '../../../../core/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

class SignUp implements UseCase<void, SignUpParams> {
  const SignUp(this._repository);
  final AuthRepository _repository;

  @override
  Future<Result<void>> call(SignUpParams params) =>
      _repository.signUp(email: params.email, password: params.password);
}

class SignUpParams extends Equatable {
  const SignUpParams({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
