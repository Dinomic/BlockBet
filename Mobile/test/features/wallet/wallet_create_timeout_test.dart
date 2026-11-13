import 'dart:typed_data';

import 'package:bbmobile/core/error/exceptions.dart';
import 'package:bbmobile/core/network/api_client.dart';
import 'package:bbmobile/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pretends to be a server that needs [serverDelay] to answer, and applies the request's
/// own `receiveTimeout` the way a real HTTP adapter would (without actually waiting).
class _SlowServerAdapter implements HttpClientAdapter {
  _SlowServerAdapter(this.serverDelay);
  final Duration serverDelay;
  Duration? seenReceiveTimeout;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body, Future<void>? cancel) async {
    seenReceiveTimeout = options.receiveTimeout;
    final limit = options.receiveTimeout;
    if (limit != null && serverDelay > limit) {
      throw DioException.receiveTimeout(timeout: limit, requestOptions: options);
    }
    return ResponseBody.fromString(
      '{"address":"0xabc","publicKey":"pub","privateKey":"SECRET"}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

WalletRemoteDataSourceImpl _dataSource(_SlowServerAdapter adapter) {
  final client = ApiClient(tokenProvider: () async => 'token');
  client.dio.httpClientAdapter = adapter;
  return WalletRemoteDataSourceImpl(client);
}

void main() {
  test('default client timeout (15s) is too short for a 30s wallet creation: reproduces the bug', () async {
    final adapter = _SlowServerAdapter(const Duration(seconds: 30));
    final client = ApiClient(tokenProvider: () async => 'token')..dio.httpClientAdapter = adapter;

    // A plain POST with the app's default options, like before the fix.
    await expectLater(
      client.dio.post<dynamic>('/blockbet/wallet', data: {'password': 'pw'}),
      throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.receiveTimeout)),
    );
  });

  test('create wallet allows a slow (30s) server and parses the response', () async {
    final adapter = _SlowServerAdapter(const Duration(seconds: 30));
    final wallet = await _dataSource(adapter).createWallet('pw');

    expect(adapter.seenReceiveTimeout, WalletRemoteDataSourceImpl.createTimeout);
    expect(wallet.address, '0xabc');
  });

  test('create wallet still maps a genuine timeout to NetworkException', () async {
    final adapter = _SlowServerAdapter(WalletRemoteDataSourceImpl.createTimeout + const Duration(seconds: 1));
    await expectLater(_dataSource(adapter).createWallet('pw'), throwsA(isA<NetworkException>()));
  });
}
