import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final email = context.select((AuthBloc b) => b.state.email);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [const BrandLogo(), const _NetworkChip()],
              ),
              const SizedBox(height: 28),
              Text("You're in", style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              if (email != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.outline, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Signed in as',
                          style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(email, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const _PlaceholderCard(title: 'Markets', body: 'Browse and bet on open markets. Coming soon.'),
              const SizedBox(height: 12),
              const _PlaceholderCard(title: 'My bets', body: 'Track your active and settled bets. Coming soon.'),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
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
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
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
  const _PlaceholderCard({required this.title, required this.body});
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(body, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: scheme.onSurfaceVariant)),
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
