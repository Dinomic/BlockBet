import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/auth_form_widgets.dart';
import '../../domain/entities/wallet.dart';
import '../bloc/wallets_bloc.dart';

class WalletsPage extends StatelessWidget {
  const WalletsPage({super.key});

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<WalletsBloc>()..add(const WalletsRequested());
    await bloc.stream.firstWhere((s) => !s.isRefreshing && s.status != WalletsStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wallets')),
      body: SafeArea(
        child: BlocBuilder<WalletsBloc, WalletsState>(
          builder: (context, state) {
            if (state.status == WalletsStatus.loading) return const _LoadingList();
            if (state.status == WalletsStatus.failure) {
              return _ErrorView(
                message: state.errorMessage ?? "Couldn't load your wallets.",
                onRetry: () => context.read<WalletsBloc>().add(const WalletsRequested()),
              );
            }
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: state.wallets.isEmpty
                  ? const _EmptyView()
                  : _WalletList(state: state),
            );
          },
        ),
      ),
    );
  }
}

class _WalletList extends StatelessWidget {
  const _WalletList({required this.state});
  final WalletsState state;

  @override
  Widget build(BuildContext context) {
    final wallets = state.wallets;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding, 4, AppTheme.screenPadding, AppTheme.screenPadding,
      ),
      itemCount: wallets.length + 1 + (state.errorMessage != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        var index = i;
        if (state.errorMessage != null) {
          if (index == 0) {
            return ErrorBanner(title: "Couldn't refresh", message: state.errorMessage!);
          }
          index--;
        }
        if (index == 0) return TotalBalanceCard(wallets: wallets, totalWei: state.totalWei);
        return WalletTile(wallet: wallets[index - 1], index: index);
      },
    );
  }
}

/// Summary of all wallets: used on the Wallets tab and on Home.
class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({super.key, required this.wallets, required this.totalWei});
  final List<Wallet> wallets;
  final BigInt totalWei;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = wallets.length;
    return Semantics(
      container: true,
      label: 'Total balance ${Wallet.formatWei(totalWei)} tokens across $count wallets',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text('Total balance',
                  style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(Wallet.formatWei(totalWei),
                          style: theme.textTheme.headlineMedium?.copyWith(fontSize: 34)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('tokens',
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(
                count == 1 ? '1 wallet' : '$count wallets',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletTile extends StatelessWidget {
  const WalletTile({super.key, required this.wallet, required this.index});
  final Wallet wallet;
  final int index;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: wallet.address));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Address copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_wallet_outlined, color: scheme.tertiary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wallet $index',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    wallet.shortAddress,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(wallet.balanceTokens,
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text('tokens',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              tooltip: 'Copy address',
              icon: const Icon(Icons.copy_rounded, size: 20),
              onPressed: () => _copy(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget bar(double h) => Container(
          height: h,
          decoration: BoxDecoration(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        );
    return Semantics(
      label: 'Loading wallets',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        children: [bar(112), const SizedBox(height: 12), bar(72), const SizedBox(height: 12), bar(72)],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      children: [
        const SizedBox(height: 64),
        Icon(Icons.account_balance_wallet_outlined, size: 48, color: theme.colorScheme.tertiary),
        const SizedBox(height: 16),
        Text('No wallets yet',
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Wallets linked to your account will show up here with their balances.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorBanner(title: "Couldn't load your wallets", message: message),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
