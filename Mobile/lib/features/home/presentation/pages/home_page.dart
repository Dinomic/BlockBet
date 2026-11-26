import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/role_widgets.dart';
import '../../../wallet/presentation/bloc/wallets_bloc.dart';
import '../../../wallet/presentation/pages/wallets_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final email = context.select((AuthBloc b) => b.state.email);
    final roles = context.select((AuthBloc b) => b.state.roles);
    final isBookie = roles.contains(UserRole.bookie);
    final isBettor = roles.contains(UserRole.bettor);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final bloc = context.read<WalletsBloc>()..add(const WalletsRequested());
            await bloc.stream.firstWhere((s) => !s.isRefreshing && s.status != WalletsStatus.loading);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [BrandLogo(), _NetworkChip()],
                ),
                const SizedBox(height: 28),
                Text('Welcome back', style: theme.textTheme.headlineMedium),
                if (email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 16),
                RoleCard(roles: roles),
                const SizedBox(height: 20),
                const _BalanceSummary(),
                const SizedBox(height: 24),
                Text('What you can do', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                if (isBookie) ...[
                  _ActionCard(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Create a bet',
                    body: 'Set the options, the stake and how long betting stays open.',
                    onTap: () => context.go(Routes.createBet),
                  ),
                  const SizedBox(height: 12),
                ],
                _ActionCard(
                  icon: Icons.casino_outlined,
                  title: isBookie && !isBettor ? 'Your bets' : 'Browse bets',
                  body: isBookie && !isBettor
                      ? 'Follow the bets you created and pick results.'
                      : 'Find an open bet and pick your option.',
                  onTap: () => context.go(Routes.bets),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletsBloc, WalletsState>(
      builder: (context, state) {
        switch (state.status) {
          case WalletsStatus.loading:
            return Container(
              height: 112,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
            );
          case WalletsStatus.failure:
            return Card(
              child: ListTile(
                leading: Icon(Icons.cloud_off_outlined, color: Theme.of(context).colorScheme.error),
                title: const Text("Couldn't load balances"),
                subtitle: Text(state.errorMessage ?? ''),
                trailing: TextButton(
                  onPressed: () => context.read<WalletsBloc>().add(const WalletsRequested()),
                  child: const Text('Retry'),
                ),
              ),
            );
          case WalletsStatus.loaded:
            return TotalBalanceCard(wallets: state.wallets, totalWei: state.totalWei);
        }
      },
    );
  }
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: scheme.secondary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('Private network', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.title, required this.body, required this.onTap});
  final IconData icon;
  final String title;
  final String body;
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
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.tertiary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
