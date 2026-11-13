import 'package:bbmobile/core/error/failures.dart';
import 'package:bbmobile/core/result.dart';
import 'package:bbmobile/core/usecase/usecase.dart';
import 'package:bbmobile/features/wallet/data/models/wallet_model.dart';
import 'package:bbmobile/features/wallet/domain/entities/wallet.dart';
import 'package:bbmobile/features/wallet/domain/usecases/get_wallets.dart';
import 'package:bbmobile/features/wallet/presentation/bloc/wallets_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetWallets extends Mock implements GetWallets {}

void main() {
  group('Wallet', () {
    test('formats wei as trimmed tokens', () {
      expect(Wallet.formatWei(BigInt.zero), '0');
      expect(Wallet.formatWei(BigInt.parse('1500000000000000000')), '1.5');
      expect(Wallet.formatWei(BigInt.parse('1234567000000000000000')), '1,234.567');
      expect(Wallet.formatWei(BigInt.one), '0');
    });

    test('shortens addresses', () {
      expect(Wallet.shortenAddress('0x1234567890abcdef1234567890abcdef12345678'), '0x1234…5678');
    });

    test('model ignores privateKey and parses large/num balances', () {
      final list = WalletModel.listFromJson({
        'wallets': [
          {'address': '0xabc', 'publicKey': 'pk', 'privateKey': 'SECRET', 'balance': 2000000000000000000},
          {'address': '0xdef', 'publicKey': 'pk2', 'privateKey': 'SECRET', 'balance': 1.0e21},
        ],
      });
      expect(list.length, 2);
      expect(list[0].balanceTokens, '2');
      expect(list[1].balanceTokens, '1,000');
      expect(list.toString().contains('SECRET'), isFalse);
    });

    test('empty / missing list', () {
      expect(WalletModel.listFromJson({}), isEmpty);
    });
  });

  group('WalletsBloc', () {
    late _MockGetWallets getWallets;
    final w = Wallet(address: '0xabc', publicKey: 'pk', balanceWei: BigInt.parse('1000000000000000000'));

    setUp(() {
      getWallets = _MockGetWallets();
      registerFallbackValue(const NoParams());
    });

    blocTest<WalletsBloc, WalletsState>(
      'loads wallets',
      build: () {
        when(() => getWallets(any())).thenAnswer((_) async => Success([w]));
        return WalletsBloc(getWallets: getWallets);
      },
      act: (b) => b.add(const WalletsRequested()),
      skip: 1,
      expect: () => [
        WalletsState(status: WalletsStatus.loaded, wallets: [w]),
      ],
    );

    blocTest<WalletsBloc, WalletsState>(
      'fails on first load',
      build: () {
        when(() => getWallets(any())).thenAnswer((_) async => const Err(NetworkFailure()));
        return WalletsBloc(getWallets: getWallets);
      },
      act: (b) => b.add(const WalletsRequested()),
      skip: 1,
      expect: () => [
        isA<WalletsState>().having((s) => s.status, 'status', WalletsStatus.failure),
      ],
    );
  });
}
