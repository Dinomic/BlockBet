import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/profile.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<ProfileModel> updateProfile(ProfileUpdate update);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  ProfileRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  static const _path = '/blockbet/infos';

  @override
  Future<ProfileModel> getProfile() async {
    final data = await _send(() => _client.dio.get<dynamic>(_path));
    return ProfileModel.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<ProfileModel> updateProfile(ProfileUpdate update) async {
    final data = await _send(
      () => _client.dio.put<dynamic>(_path, data: ProfileModel.updateToJson(update)),
    );
    return ProfileModel.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _send(Future<Response<dynamic>> Function() request) async {
    try {
      return (await request()).data;
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
