import 'dart:convert';
import 'dart:typed_data';

import 'package:bbmobile/core/error/exceptions.dart';
import 'package:bbmobile/core/error/failures.dart';
import 'package:bbmobile/core/network/api_client.dart';
import 'package:bbmobile/core/result.dart';
import 'package:bbmobile/features/wallet/data/datasources/wallet_remote_data_source.dart';
import 'package:bbmobile/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:bbmobile/features/wallet/domain/entities/wallet.dart';
import 'package:bbmobile/features/wallet/domain/usecases/transfer_tokens.dart';
import 'package:bbmobile/features/wallet/presentation/bloc/transfer_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransferTokens extends Mock implements TransferTokens {}

class _MockRemote extends Mock implements WalletRemoteDataSource {}

/// Records what is sent and answers with a canned status/body.
class _Adapter implements HttpClientAdapter {
  String? sentBody;
  String? sentMethod;
  String? sentPath;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    sentMethod = o.method;
    sentPath = o.path;
    final bytes = <int>[];
    if (body != null) {
      await for (final c in body) {
        bytes.addAll(c);
      }
    }
    sentBody = utf8.decode(bytes);
    return ResponseBody.fromString('{"txHash":"0xhash"}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Wallet.parseTokens', () {
    BigInt tokens(String s) => BigInt.parse(s);

    test('parses whole, decimal and comma amounts into wei', () {
      expect(Wallet.parseTokens('1'), tokens('1000000000000000000'));
      expect(Wallet.parseTokens('1.5'), tokens('1500000000000000000'));
      expect(Wallet.parseTokens('0,5'), tokens('500000000000000000'));
      expect(Wallet.parseTokens('.25'), tokens('250000000000000000'));
      expect(Wallet.parseTokens('0.000000000000000001'), BigInt.one);
    });

    test('rejects empty, malformed and over-precise input', () {
      for (final bad in ['', ' ', '.', 'abc', '1.2.3', '-1', '1e5', '0.0000000000000000001']) {
        expect(Wallet.parseTokens(bad), isNull, reason: '"$bad"');
      }
    });

    test('address validation', () {
      expect(Wallet.isValidAddress('0x${'a' * 40}'), isTrue);
      expect(Wallet.isValidAddress('0x${'a' * 39}'), isFalse);
      expect(Wallet.isValidAddress('a' * 42), isFalse);
    });
  });

  group('transfer request', () {
    test('sends amounts above 2^63 exactly, as a JSON number, without any private key', () async {
      final adapter = _Adapter();
      final client = ApiClient(tokenProvider: () async => 't')..dio.httpClientAdapter = adapter;
      final hash = await WalletRemoteDataSourceImpl(client).transferTokens(
        fromAddress: '0x${'a' * 40}',
        toAddress: '0x${'b' * 40}',
        amountWei: BigInt.parse('9500000000000000000'), // > 9.22e18, overflows a Dart int
        idempotencyKey: 'key-123',
      );

      expect(hash, '0xhash');
      expect(adapter.sentMethod, 'PUT');
      expect(adapter.sentPath, '/blockbet/transfer-tokens');
      expect(adapter.sentBody, contains('"amount":9500000000000000000,'));
      expect(adapter.sentBody, isNot(contains('rivate')));
      final json = jsonDecode(adapter.sentBody!) as Map<String, dynamic>;
      expect(json['fromAddress'], '0x${'a' * 40}');
      expect(json['toAddress'], '0x${'b' * 40}');
      expect(json['idempotencyKey'], 'key-123');
    });

    test('a small amount and the key are both in a well-formed body', () async {
      final adapter = _Adapter();
      final client = ApiClient(tokenProvider: () async => 't')..dio.httpClientAdapter = adapter;
      await WalletRemoteDataSourceImpl(client).transferTokens(
        fromAddress: '0x${'a' * 40}',
        toAddress: '0x${'b' * 40}',
        amountWei: BigInt.one,
        idempotencyKey: 'abc_DEF-1',
      );
      final json = jsonDecode(adapter.sentBody!) as Map<String, dynamic>;
      expect(json['idempotencyKey'], 'abc_DEF-1');
      expect(json['amount'], 1);
    });
  });

  group('WalletRepositoryImpl.transferTokens', () {
    late _MockRemote remote;
    setUpAll(() => registerFallbackValue(BigInt.zero));
    setUp(() => remote = _MockRemote());

    Future<Result<String>> run() => WalletRepositoryImpl(remote: remote)
        .transferTokens(fromAddress: 'f', toAddress: 't', amountWei: BigInt.one, idempotencyKey: 'k');

    void remoteThrows(Object e) => when(() => remote.transferTokens(
          fromAddress: any(named: 'fromAddress'),
          toAddress: any(named: 'toAddress'),
          amountWei: any(named: 'amountWei'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenThrow(e);

    Failure failureOf(Result<String> r) => r.when(success: (_) => fail('expected failure'), failure: (f) => f);

    test('5xx becomes an actionable message instead of "can\'t reach the server"', () async {
      remoteThrows(ServerException('boom', statusCode: 500));
      final f = failureOf(await run());
      expect(f, isNot(isA<NetworkFailure>()));
      expect(f.message, contains('Check your wallet balances'));
    });

    test('timeout says a retry is safe (idempotency key)', () async {
      remoteThrows(const NetworkException());
      final f = failureOf(await run());
      expect(f.message, contains("won't be sent twice"));
    });

    test('400 (e.g. insufficient balance) shows the server message', () async {
      remoteThrows(ServerException('Insufficient balance: the wallet must cover the amount plus the network fee',
          statusCode: 400));
      expect(failureOf(await run()).message, startsWith('Insufficient balance'));
    });

    test('4xx keeps the server message', () async {
      remoteThrows(ServerException('Wallet not found with associated account', statusCode: 404));
      expect(failureOf(await run()).message, 'Wallet not found with associated account');
    });
  });

  group('TransferBloc', () {
    late _MockTransferTokens transfer;
    final params =
        TransferParams(fromAddress: 'f', toAddress: 't', amountWei: BigInt.one, idempotencyKey: 'k');

    setUp(() {
      transfer = _MockTransferTokens();
      registerFallbackValue(params);
    });

    blocTest<TransferBloc, TransferState>(
      'success -> submitting then success with tx hash',
      build: () {
        when(() => transfer(any())).thenAnswer((_) async => const Success('0xhash'));
        return TransferBloc(transferTokens: transfer);
      },
      act: (b) => b.add(TransferSubmitted(params)),
      expect: () => const [
        TransferState(status: TransferStatus.submitting),
        TransferState(status: TransferStatus.success, txHash: '0xhash'),
      ],
    );

    blocTest<TransferBloc, TransferState>(
      'failure -> error message, and can be dismissed',
      build: () {
        when(() => transfer(any())).thenAnswer((_) async => const Err(ServerFailure('nope')));
        return TransferBloc(transferTokens: transfer);
      },
      act: (b) async {
        b.add(TransferSubmitted(params));
        await Future<void>.delayed(Duration.zero);
        b.add(const TransferErrorDismissed());
      },
      expect: () => const [
        TransferState(status: TransferStatus.submitting),
        TransferState(status: TransferStatus.failure, errorMessage: 'nope'),
        TransferState(),
      ],
    );

    blocTest<TransferBloc, TransferState>(
      'double tap sends only once',
      build: () {
        when(() => transfer(any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return const Success('0xhash');
        });
        return TransferBloc(transferTokens: transfer);
      },
      act: (b) {
        b.add(TransferSubmitted(params));
        b.add(TransferSubmitted(params));
      },
      wait: const Duration(milliseconds: 60),
      verify: (_) => verify(() => transfer(any())).called(1),
    );
  });
}
