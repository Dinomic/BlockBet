import 'dart:convert';

import '../../domain/entities/bet.dart';
import '../../domain/entities/betting_log.dart';

class BetModel {
  const BetModel._();

  /// Parses `BetResponse`.
  static Bet fromJson(Map<String, dynamic> json) {
    final options = json['options'];
    return Bet(
      id: (json['betId'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      description: _text(json['description']),
      imageUrl: _text(json['imageUrl']),
      bookieAddress: (json['bookieAddress'] as String?) ?? '',
      options: options is List
          ? [for (final o in options) _option(Map<String, dynamic>.from(o as Map))]
          : const [],
      stake: _bigInt(json['stake']) ?? BigInt.zero,
      pool: _bigInt(json['pool']) ?? BigInt.zero,
      status: _status(json['status']),
      closeTime: _date(json['closeTime']),
      winner: json['winner'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }

  /// Parses `BetsGetResponse`.
  static BetsPage pageFromJson(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    final items = json['result'];
    return BetsPage(
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      bets: items is List
          ? [for (final e in items) fromJson(Map<String, dynamic>.from(e as Map))]
          : const [],
    );
  }

  /// Parses `BettingLogsGetResponse`.
  static BettingLogsPage logsPageFromJson(dynamic data) {
    final json = Map<String, dynamic>.from(data as Map);
    final items = json['result'];
    return BettingLogsPage(
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      logs: items is List
          ? [for (final e in items) _log(Map<String, dynamic>.from(e as Map))]
          : const [],
    );
  }

  static BettingLog _log(Map<String, dynamic> json) => BettingLog(
        id: (json['bettingLogId'] as num?)?.toInt() ?? 0,
        betId: (json['betId'] as num?)?.toInt() ?? 0,
        action: switch (json['action']) {
          'BET_CREATED' => BettingAction.created,
          'BET_PLACED' => BettingAction.placed,
          'BET_RESOLVED' => BettingAction.resolved,
          'BET_REFUNDED' => BettingAction.refunded,
          'BET_CAUTION_FLAGGED' => BettingAction.cautionFlagged,
          _ => BettingAction.unknown,
        },
        walletAddress: _text(json['walletAddress']),
        option: _text(json['option']),
        amount: _bigInt(json['amount']),
        txHash: _text(json['txHash']),
        detail: _text(json['detail']),
        createdAt: _date(json['createdAt']),
      );

  /// Body (JSON text) of `POST /bookie/bets/multiple-option-simple-pool`.
  ///
  /// Built by hand because the stake is a wei amount: a JSON integer that can exceed 2^63 (more than
  /// ~9 tokens), which a Dart `int` cannot hold and `jsonEncode` cannot write from a `BigInt`.
  static String createBody(NewBet bet) {
    final rest = jsonEncode({
      'fromAddress': bet.fromAddress,
      'title': bet.title,
      if (bet.description != null) 'description': bet.description,
      if (bet.imageUrl != null) 'imageUrl': bet.imageUrl,
      'options': bet.options,
      'durationSeconds': bet.duration.inSeconds,
    });
    return '${rest.substring(0, rest.length - 1)},"stake":${bet.stakeWei}}';
  }

  static BetOption _option(Map<String, dynamic> json) => BetOption(
        letter: (json['option'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        bettors: (json['bettors'] as num?)?.toInt() ?? 0,
      );

  static BetStatus _status(Object? v) => switch (v) {
        'OPEN' => BetStatus.open,
        'CLOSED' => BetStatus.closed,
        'RESOLVED' => BetStatus.resolved,
        'REFUNDED' => BetStatus.refunded,
        'CAUTION' => BetStatus.caution,
        _ => BetStatus.unknown,
      };

  static String? _text(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static BigInt? _bigInt(Object? v) {
    if (v is int) return BigInt.from(v);
    if (v is num) return BigInt.from(v);
    if (v is String) return BigInt.tryParse(v);
    return null;
  }
}
