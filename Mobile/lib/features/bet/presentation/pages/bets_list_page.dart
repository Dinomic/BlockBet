import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/role_widgets.dart';
import '../../../auth/presentation/widgets/auth_form_widgets.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../../../wallet/presentation/bloc/wallets_bloc.dart';
import '../../domain/entities/bet.dart';
import '../bloc/bets_bloc.dart';
import '../widgets/bet_widgets.dart';

enum _Filter { all, mine }

/// The "Bets" tab. Everybody can browse; what the role adds is shown right on the page:
/// bookies get a "Created by you" filter and the Create button.
class BetsListPage extends StatefulWidget {
  const BetsListPage({super.key});

  @override
  State<BetsListPage> createState() => _BetsListPageState();
}

class _BetsListPageState extends State<BetsListPage> {
  _Filter _filter = _Filter.all;

  Future<void> _refresh() async {
    final bloc = context.read<BetsBloc>()..add(const BetsRequested());
    await bloc.stream.firstWhere((s) => !s.isRefreshing && s.status != BetsStatus.loading);
  }

  /// Detail and create pages change bets, so reload the list when coming back.
  Future<void> _open(String location) async {
    final bloc = context.read<BetsBloc>();
    await context.push<Object?>(location);
    if (!bloc.isClosed) bloc.add(const BetsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.select((AuthBloc b) => b.state);
    final myAddresses = context.select(
      (WalletsBloc b) => {for (final w in b.state.wallets) w.address.toLowerCase()},
    );
    final isBookie = auth.isBookie;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bets'),
        actions: [
          IconButton(
            tooltip: 'Betting history',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push(Routes.bettingLogs),
          ),
          if (auth.primaryRole != null)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.screenPadding),
              child: Center(child: RoleBadge(role: auth.primaryRole!, dense: true)),
            ),
        ],
      ),
      floatingActionButton: isBookie
          ? FloatingActionButton.extended(
              onPressed: () => _open(Routes.createBet),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create bet'),
            )
          : null,
      body: SafeArea(
        child: BlocBuilder<BetsBloc, BetsState>(
          builder: (context, state) {
            if (state.status == BetsStatus.loading) return const _LoadingList();
            if (state.status == BetsStatus.failure) {
              return _ErrorView(
                message: state.errorMessage ?? "Couldn't load the bets.",
                onRetry: () => context.read<BetsBloc>().add(const BetsRequested()),
              );
            }
            final bets = _filter == _Filter.mine
                ? state.bets.where((b) => b.isCreatedBy(myAddresses)).toList()
                : state.bets;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppTheme.screenPadding, 8, AppTheme.screenPadding,
                  // Room for the floating button.
                  isBookie ? 96 : AppTheme.screenPadding,
                ),
                children: [
                  if (isBookie) ...[
                    SegmentedButton<_Filter>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: _Filter.all, label: Text('All bets')),
                        ButtonSegment(
                          value: _Filter.mine,
                          icon: Icon(Icons.storefront_outlined, size: 18),
                          label: Text('Created by me'),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (s) => setState(() => _filter = s.first),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.errorMessage != null) ...[
                    ErrorBanner(title: "Couldn't load the bets", message: state.errorMessage!),
                    const SizedBox(height: 12),
                  ],
                  if (bets.isEmpty)
                    _EmptyView(mine: _filter == _Filter.mine, isBookie: isBookie)
                  else
                    for (final bet in bets) ...[
                      _BetCard(
                        bet: bet,
                        mine: bet.isCreatedBy(myAddresses),
                        onTap: () => _open(Routes.betPath(bet.id)),
                      ),
                      const SizedBox(height: 12),
                    ],
                  if (state.hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: state.isLoadingMore
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                          : OutlinedButton(
                              onPressed: () => context.read<BetsBloc>().add(const BetsMoreRequested()),
                              child: const Text('Load more'),
                            ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BetCard extends StatelessWidget {
  const _BetCard({required this.bet, required this.mine, required this.onTap});
  final Bet bet;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(bet.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  BetStatusChip(status: bet.status),
                ],
              ),
              if (mine) ...[const SizedBox(height: 6), const MineChip()],
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final o in bet.options)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bet.winner == o.letter ? scheme.secondary.withValues(alpha: 0.15) : scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                      ),
                      child: Text('${o.letter} · ${o.name}', style: theme.textTheme.labelMedium),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BetFact(label: 'Stake', value: '${Wallet.formatWei(bet.stake)} tokens'),
                  ),
                  Expanded(
                    child: BetFact(label: 'Pool', value: '${Wallet.formatWei(bet.pool)} tokens'),
                  ),
                ],
              ),
              if (bet.status == BetStatus.open && bet.closeTime != null) ...[
                const SizedBox(height: 10),
                Text(describeCloseTime(bet.closeTime),
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ],
          ),
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
    Widget bar() => Container(
          height: 140,
          decoration: BoxDecoration(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        );
    return Semantics(
      label: 'Loading bets',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        children: [bar(), const SizedBox(height: 12), bar(), const SizedBox(height: 12), bar()],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.mine, required this.isBookie});
  final bool mine;
  final bool isBookie;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = mine
        ? 'Bets you create will show up here.'
        : isBookie
            ? 'Tap “Create bet” to open the first one.'
            : 'Bets from bookies will show up here.';
    return Column(
      children: [
        const SizedBox(height: 56),
        Icon(Icons.casino_outlined, size: 48, color: theme.colorScheme.tertiary),
        const SizedBox(height: 16),
        Text(mine ? 'No bets created yet' : 'No bets yet',
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
            ErrorBanner(title: "Couldn't load the bets", message: message),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
