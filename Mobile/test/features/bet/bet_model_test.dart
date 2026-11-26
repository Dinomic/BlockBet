import 'dart:convert';

import 'package:bbmobile/features/bet/data/models/bet_model.dart';
import 'package:bbmobile/features/bet/domain/entities/bet.dart';
import 'package:bbmobile/features/bet/domain/entities/betting_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a bet with its options, status and winner', () {
    final bet = BetModel.fromJson({
      'betId': 7,
      'title': 'Arsenal vs MU',
      'bookieAddress': '0xABC',
      'options': [
        {'option': 'A', 'name': 'Arsenal', 'bettors': 2},
        {'option': 'B', 'name': 'MU', 'bettors': 1},
      ],
      'stake': 1000000000000000,
      'pool': 3000000000000000,
      'closeTime': '2026-01-01T10:00:00Z',
      'status': 'RESOLVED',
      'winner': 'A',
    });

    expect(bet.id, 7);
    expect(bet.options.map((o) => o.name), ['Arsenal', 'MU']);
    expect(bet.bettors, 3);
    expect(bet.stake, BigInt.from(1000000000000000));
    expect(bet.status, BetStatus.resolved);
    expect(bet.winningOption?.name, 'Arsenal');
    expect(bet.isCreatedBy({'0xabc'}), isTrue);
    expect(bet.isCreatedBy({'0xdef'}), isFalse);
  });

  test('an unknown status does not break parsing', () {
    final bet = BetModel.fromJson({'betId': 1, 'status': 'SOMETHING_NEW'});
    expect(bet.status, BetStatus.unknown);
    expect(bet.options, isEmpty);
  });

  test('parses a page of betting logs', () {
    final page = BetModel.logsPageFromJson({
      'offset': 0,
      'limit': 20,
      'total': 5,
      'result': [
        {
          'bettingLogId': 9,
          'betId': 3,
          'action': 'BET_PLACED',
          'option': 'B',
          'amount': 1000000000000000,
          'createdAt': '2026-01-01T10:00:00Z',
        },
        {'bettingLogId': 8, 'betId': 3, 'action': 'SOMETHING_NEW'},
      ],
    });

    expect(page.total, 5);
    expect(page.logs.first.action, BettingAction.placed);
    expect(page.logs.first.option, 'B');
    expect(page.logs.first.amount, BigInt.from(1000000000000000));
    expect(page.logs.last.action, BettingAction.unknown);
  });

  test('the create body keeps a stake above 2^63 wei exact', () {
    final body = BetModel.createBody(NewBet(
      fromAddress: '0xabc',
      title: 'T',
      options: const ['A', 'B'],
      stakeWei: BigInt.parse('12000000000000000000'), // 12 tokens
      duration: const Duration(hours: 2),
    ));

    final json = jsonDecode(body) as Map<String, dynamic>;
    expect(json['options'], ['A', 'B']);
    expect(json['durationSeconds'], 7200);
    expect(json.containsKey('description'), isFalse);
    expect(body, contains('"stake":12000000000000000000}'));
  });
}
