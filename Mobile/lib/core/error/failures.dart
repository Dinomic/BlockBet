import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = "Can't reach the server. Check your connection and try again."]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Email or password is incorrect. Check them and try again.']);
}

class EmailTakenFailure extends Failure {
  const EmailTakenFailure([super.message = 'An account with this email already exists. Log in instead.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error.']);
}
