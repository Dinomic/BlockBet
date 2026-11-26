import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/bet.dart';
import '../../domain/entities/betting_log.dart';
import '../models/bet_model.dart';

abstract class BetRemoteDataSource {
  Future<BetsPage> getBets({required int offset, required int limit});
  Future<Bet> getBet(int betId);
  Future<BettingLogsPage> getBettingLogs({required int offset, required int limit});
  Future<String> placeBet({required int betId, required String fromAddress, required String option});
  Future<int> createBet(NewBet bet);
  Future<String> resolveBet({required int betId, required String winner});
}

class BetRemoteDataSourceImpl implements BetRemoteDataSource {
  BetRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  /// The contract kind the app supports today; the kind is part of the write endpoints' paths.
  static const _kind = 'multiple-option-simple-pool';

  /// Writes wait on the server until the transaction is mined, which takes longer than a normal call.
  static final _writeOptions = Options(receiveTimeout: const Duration(seconds: 90));

  @override
  Future<BetsPage> getBets({required int offset, required int limit}) => _call(() async {
        final response = await _client.dio.get<dynamic>(
          '/blockbet/bets',
          queryParameters: {'offset': offset, 'limit': limit},
        );
        return BetModel.pageFromJson(response.data);
      });

  @override
  Future<Bet> getBet(int betId) => _call(() async {
        final response = await _client.dio.get<dynamic>('/blockbet/bets/$betId');
        return BetModel.fromJson(Map<String, dynamic>.from(response.data as Map));
      });

  @override
  Future<BettingLogsPage> getBettingLogs({required int offset, required int limit}) => _call(() async {
        final response = await _client.dio.get<dynamic>(
          '/bettor/betting-logs',
          queryParameters: {'offset': offset, 'limit': limit},
        );
        return BetModel.logsPageFromJson(response.data);
      });

  @override
  Future<String> placeBet({required int betId, required String fromAddress, required String option}) =>
      _call(() async {
        final response = await _client.dio.post<dynamic>(
          '/bettor/bets/$_kind/$betId/place',
          data: {'fromAddress': fromAddress, 'option': option},
          options: _writeOptions,
        );
        return (response.data as Map)['txHash'] as String;
      });

  @override
  Future<int> createBet(NewBet bet) => _call(() async {
        final response = await _client.dio.post<dynamic>(
          '/bookie/bets/$_kind',
          data: BetModel.createBody(bet),
          options: _writeOptions.copyWith(contentType: Headers.jsonContentType),
        );
        return ((response.data as Map)['betId'] as num).toInt();
      });

  @override
  Future<String> resolveBet({required int betId, required String winner}) => _call(() async {
        final response = await _client.dio.put<dynamic>(
          '/bookie/bets/$_kind/$betId/result',
          data: {'winner': winner},
          options: _writeOptions,
        );
        return (response.data as Map)['txHash'] as String;
      });

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
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
