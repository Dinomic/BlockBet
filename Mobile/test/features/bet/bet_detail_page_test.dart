import 'package:bbmobile/features/auth/domain/entities/user_role.dart';
import 'package:bbmobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bbmobile/features/bet/domain/entities/bet.dart';
import 'package:bbmobile/features/bet/presentation/bloc/bet_detail_bloc.dart';
import 'package:bbmobile/features/bet/presentation/pages/bet_detail_page.dart';
import 'package:bbmobile/features/wallet/domain/entities/wallet.dart';
import 'package:bbmobile/features/wallet/presentation/bloc/wallets_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockWalletsBloc extends MockBloc<WalletsEvent, WalletsState> implements WalletsBloc {}

class MockDetailBloc extends MockBloc<BetDetailEvent, BetDetailState> implements BetDetailBloc {}

void main() {
  final myWallet = Wallet(address: '0xAAAA000000000000000000000000000000000001', publicKey: 'pk', balanceWei: BigInt.from(10).pow(18));

  Bet bet({BetStatus status = BetStatus.open, String bookie = '0xbbbb000000000000000000000000000000000002'}) => Bet(
        id: 1,
        title: 'Arsenal vs MU',
        bookieAddress: bookie,
        options: const [
          BetOption(letter: 'A', name: 'Arsenal', bettors: 1),
          BetOption(letter: 'B', name: 'MU', bettors: 0),
        ],
        stake: BigInt.from(10).pow(15),
        pool: BigInt.from(10).pow(15),
        status: status,
        winner: status == BetStatus.resolved ? 'A' : null,
      );

  Future<void> pump(WidgetTester tester, {required List<UserRole> roles, required Bet bet}) async {
    final auth = MockAuthBloc();
    when(() => auth.state).thenReturn(AuthState(status: AuthStatus.authenticated, roles: roles));
    final wallets = MockWalletsBloc();
    when(() => wallets.state).thenReturn(WalletsState(status: WalletsStatus.loaded, wallets: [myWallet]));
    final detail = MockDetailBloc();
    when(() => detail.state).thenReturn(BetDetailState(status: BetDetailStatus.loaded, bet: bet));

    await tester.pumpWidget(MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: auth),
          BlocProvider<WalletsBloc>.value(value: wallets),
          BlocProvider<BetDetailBloc>.value(value: detail),
        ],
        child: const BetDetailPage(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a bettor can pick an option and place the bet on an open bet', (tester) async {
    await pump(tester, roles: [UserRole.bettor], bet: bet());

    expect(find.text('PICK AN OPTION'), findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'Place bet · 0.001 tokens');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.tap(find.text('Arsenal'));
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
  });

  testWidgets('a bookie without the bettor role is told why it can not bet', (tester) async {
    await pump(tester, roles: [UserRole.bookie], bet: bet());

    expect(find.text('Only bettors can place bets'), findsOneWidget);
    expect(find.textContaining('Place bet'), findsNothing);
  });

  testWidgets('the bookie of a closed bet can pick the winner, other bookies only wait', (tester) async {
    await pump(tester, roles: [UserRole.bookie], bet: bet(status: BetStatus.closed, bookie: myWallet.address.toLowerCase()));
    expect(find.text('PICK THE WINNER'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Confirm result'), findsOneWidget);

    await pump(tester, roles: [UserRole.bookie], bet: bet(status: BetStatus.closed));
    expect(find.text('Betting is closed'), findsOneWidget);
    expect(find.text('Confirm result'), findsNothing);
  });

  testWidgets('a resolved bet shows its winner to everybody', (tester) async {
    await pump(tester, roles: [UserRole.bettor], bet: bet(status: BetStatus.resolved));

    expect(find.text('Winner: A · Arsenal'), findsOneWidget);
  });
}
