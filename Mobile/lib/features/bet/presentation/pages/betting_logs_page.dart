import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/auth_form_widgets.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../../domain/entities/betting_log.dart';
import '../bloc/betting_logs_bloc.dart';

/// The caller's own betting history: bets created, placed and resolved, newest first.
class BettingLogsPage extends StatelessWidget {
  const BettingLogsPage({super.key});

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<BettingLogsBloc>()..add(const BettingLogsRequested());
    await bloc.stream.firstWhere((s) => !s.isRefreshing && s.status != BettingLogsStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Betting history')),
      body: SafeArea(
        child: BlocBuilder<BettingLogsBloc, BettingLogsState>(
          builder: (context, state) {
            if (state.status == BettingLogsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == BettingLogsStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ErrorBanner(
                        title: "Couldn't load your betting history",
                        message: state.errorMessage ?? 'Try again in a moment.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.read<BettingLogsBloc>().add(const BettingLogsRequested()),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => _refresh(context),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.screenPadding),
                children: [
                  if (state.errorMessage != null) ...[
                    ErrorBanner(title: "Couldn't load your betting history", message: state.errorMessage!),
                    const SizedBox(height: 12),
                  ],
                  if (state.logs.isEmpty)
                    const _Empty()
                  else
                    for (final log in state.logs) ...[
                      _LogCard(log: log),
                      const SizedBox(height: 10),
                    ],
                  if (state.hasMore)
                    state.isLoadingMore
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                        : OutlinedButton(
                            onPressed: () => context.read<BettingLogsBloc>().add(const BettingLogsMoreRequested()),
                            child: const Text('Load more'),
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

extension on BettingAction {
  IconData get icon => switch (this) {
        BettingAction.created => Icons.add_circle_outline_rounded,
        BettingAction.placed => Icons.casino_outlined,
        BettingAction.resolved => Icons.emoji_events_outlined,
        BettingAction.refunded => Icons.undo_rounded,
        BettingAction.cautionFlagged => Icons.warning_amber_rounded,
        BettingAction.unknown => Icons.history_rounded,
      };
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});
  final BettingLog log;

  static String _dateTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtle = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final lines = <String>[
      if (log.option != null) 'Option ${log.option}',
      if (log.amount != null) '${Wallet.formatWei(log.amount!)} tokens',
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Opens the bet the action was on.
        onTap: log.betId > 0 ? () => context.push(Routes.betPath(log.betId)) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(log.action.icon, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.action.label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(['Bet #${log.betId}', ...lines].join(' · '), style: theme.textTheme.bodyMedium),
                    if (log.detail != null) ...[
                      const SizedBox(height: 2),
                      Text(log.detail!, style: subtle),
                    ],
                    if (log.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(_dateTime(log.createdAt!), style: subtle),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: 56),
        Icon(Icons.history_rounded, size: 48, color: theme.colorScheme.tertiary),
        const SizedBox(height: 16),
        Text('No betting activity yet', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Bets you create, place or resolve will show up here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
