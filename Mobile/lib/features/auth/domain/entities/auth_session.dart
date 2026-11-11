import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  const AuthSession({required this.token, this.email});
  final String token;
  final String? email;

  @override
  List<Object?> get props => [token, email];
}
