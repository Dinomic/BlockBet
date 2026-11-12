import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_session_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSessionModel> login({required String email, required String password});
  Future<void> signUp({required String email, required String password});

  /// Revokes the refresh token on the server (ends the session there).
  Future<void> logout({required String refreshToken});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  @override
  Future<AuthSessionModel> login({required String email, required String password}) async {
    final data = await _post('/auth/login', {'email': email, 'password': password});
    return AuthSessionModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    await _post('/auth/sign-up', {'email': email, 'password': password});
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await _post('/auth/logout', {'refreshToken': refreshToken});
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client.dio.post<dynamic>(path, data: body);
      return response.data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == null) throw const NetworkException();
      final data = e.response?.data;
      final message = data is Map && data['message'] is String
          ? data['message'] as String
          : 'Request failed ($status)';
      throw ServerException(message, statusCode: status);
    }
  }
}
