import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/wallet.dart';
import '../models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  Future<List<Wallet>> getWallets();
  Future<Wallet> createWallet(String password);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  static const createTimeout = Duration(seconds: 90);
  static const _listPath = '/blockbet/wallets';
  static const _createPath = '/blockbet/wallet';

  @override
  Future<List<Wallet>> getWallets() async {
    final data = await _send(() => _client.dio.get<dynamic>(_listPath));
    return WalletModel.listFromJson(data);
  }

  @override
  Future<Wallet> createWallet(String password) async {
    final data = await _send(
      () => _client.dio.post<dynamic>(
        _createPath,
        data: {'password': password},
        // Key generation + faucet funding wait for the chain to confirm: far slower than
        // the 15s default, and timing out here leaves a wallet that exists but looks failed.
        options: Options(receiveTimeout: createTimeout),
      ),
    );
    return WalletModel.createdFromJson(Map<String, dynamic>.from(data as Map));
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
