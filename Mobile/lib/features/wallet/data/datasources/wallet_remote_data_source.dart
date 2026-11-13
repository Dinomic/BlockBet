import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/wallet.dart';
import '../models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  Future<List<Wallet>> getWallets();
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  static const _path = '/blockbet/wallets';

  @override
  Future<List<Wallet>> getWallets() async {
    try {
      final response = await _client.dio.get<dynamic>(_path);
      return WalletModel.listFromJson(response.data);
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
