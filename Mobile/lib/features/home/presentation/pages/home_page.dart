import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../wallet/presentation/bloc/wallets_bloc.dart';
import '../../../wallet/presentation/pages/wallets_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final email = context.select((AuthBloc b) => b.state.email);

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
                const SizedBox(height: 20),
                const _BalanceSummary(),
                const SizedBox(height: 24),
                Text('Coming up', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                const _PlaceholderCard(
                  icon: Icons.casino_outlined,
                  title: 'Markets',
                  body: 'Browse and bet on open markets.',
                ),
                const SizedBox(height: 12),
                const _PlaceholderCard(
                  icon: Icons.receipt_long_outlined,
                  title: 'My bets',
                  body: 'Track your active and settled bets.',
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

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return CustomPaint(
      painter: _DashedBorderPainter(color: scheme.outline, radius: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: scheme.onSurfaceVariant),
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
            Text('Soon', style: theme.textTheme.labelMedium?.copyWith(color: scheme.tertiary)),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color || old.radius != radius;
}
