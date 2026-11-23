import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/receipt.dart';
import '../models/receipt_model.dart';

abstract class ReceiptRemoteDataSource {
  Future<ReceiptsPage> getReceipts({required int offset, required int limit});
}

class ReceiptRemoteDataSourceImpl implements ReceiptRemoteDataSource {
  ReceiptRemoteDataSourceImpl(this._client);
  final ApiClient _client;

  static const _path = '/blockbet/receipts';

  @override
  Future<ReceiptsPage> getReceipts({required int offset, required int limit}) async {
    try {
      final response = await _client.dio.get<dynamic>(
        _path,
        queryParameters: {'offset': offset, 'limit': limit},
      );
      return ReceiptModel.pageFromJson(response.data);
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
