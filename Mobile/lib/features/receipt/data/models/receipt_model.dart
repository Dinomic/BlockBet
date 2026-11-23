import '../../domain/entities/receipt.dart';

class ReceiptModel {
  const ReceiptModel._();

  /// Parses one item of `ReceiptsGetResponse.result`.
  static Receipt fromJson(Map<String, dynamic> json) => Receipt(
        hash: json['hash'] as String,
        fromAddress: (json['fromAddress'] as String?) ?? '',
        toAddress: (json['toAddress'] as String?) ?? '',
        type: _parseType(json['transactionType']),
        success: json['success'] is bool ? json['success'] as bool : null,
        blockHash: json['blockHash'] as String?,
        blockNumber: _parseBigInt(json['blockNumber']),
        gasUsed: _parseBigInt(json['gasUsed']),
        effectiveGasPrice: _parseBigInt(json['effectiveGasPrice']),
      );

  /// Parses `ReceiptsGetResponse`.
  static ReceiptsPage pageFromJson(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    final items = json['result'];
    return ReceiptsPage(
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      receipts: items is List
          ? [for (final e in items) fromJson(Map<String, dynamic>.from(e as Map))]
          : const [],
    );
  }

  static ReceiptType _parseType(Object? v) => switch (v) {
        'FUNDING' => ReceiptType.funding,
        'TOKEN_TRANSFER' => ReceiptType.tokenTransfer,
        _ => ReceiptType.unknown,
      };

  static BigInt? _parseBigInt(Object? v) {
    if (v is int) return BigInt.from(v);
    if (v is num) return BigInt.from(v);
    if (v is String) return BigInt.tryParse(v);
    return null;
  }
}
