import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/wallet.dart';
import '../models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  Future<List<Wallet>> getWallets();
  Future<Wallet> createWallet(String password);
  Future<String> transferTokens({
    required String fromAddress,
    required String toAddress,
    required BigInt amountWei,
    required String idempotencyKey,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  WalletRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  static const createTimeout = Duration(seconds: 90);
  static const _listPath = '/blockbet/wallets';
  static const _createPath = '/blockbet/wallet';
  static const _transferPath = '/blockbet/transfer-tokens';

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

  @override
  Future<String> transferTokens({
    required String fromAddress,
    required String toAddress,
    required BigInt amountWei,
    required String idempotencyKey,
  }) async {
    // Wei amounts exceed a 64-bit int (10 tokens = 1e19 > 2^63), so the JSON is written by hand
    // and the amount goes out as a plain integer literal. The private key is never sent.
    // (A plain String body is sent as-is; unlike a stream it can be replayed after a token refresh.)
    final body = '{"fromAddress":${jsonEncode(fromAddress)},'
        '"toAddress":${jsonEncode(toAddress)},'
        '"amount":$amountWei,'
        '"idempotencyKey":${jsonEncode(idempotencyKey)}}';
    final data = await _send(() => _client.dio.put<dynamic>(_transferPath, data: body));
    return (data as Map)['txHash'] as String;
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
