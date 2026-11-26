import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/bet.dart';

extension BetStatusStyle on BetStatus {
  Color color(ColorScheme scheme) => switch (this) {
        BetStatus.open => scheme.secondary,
        BetStatus.closed => scheme.tertiary,
        BetStatus.resolved => scheme.onSurfaceVariant,
        BetStatus.refunded => scheme.onSurfaceVariant,
        BetStatus.caution => scheme.error,
        BetStatus.unknown => scheme.onSurfaceVariant,
      };
}

class BetStatusChip extends StatelessWidget {
  const BetStatusChip({super.key, required this.status});
  final BetStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = status.color(theme.colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
      ),
      child: Text(status.label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
    );
  }
}

/// "Created by you" marker for the bets whose bookie wallet belongs to the signed-in account.
class MineChip extends StatelessWidget {
  const MineChip({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.storefront_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Text('Created by you',
            style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

/// "Closes in 2h 5m", "Closed 3 days ago" or the plain date, depending on how far away it is.
String describeCloseTime(DateTime? closeTime, {DateTime? now}) {
  if (closeTime == null) return '';
  final diff = closeTime.difference(now ?? DateTime.now());
  final future = !diff.isNegative;
  final span = _span(diff.abs());
  return future ? 'Closes in $span' : 'Closed $span ago';
}

String _span(Duration d) {
  if (d.inDays >= 1) return '${d.inDays} day${d.inDays == 1 ? '' : 's'}';
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m';
  if (d.inMinutes >= 1) return '${d.inMinutes}m';
  return 'less than a minute';
}

/// "Pool 0.3 tokens" style label/value pair for the card and detail header.
class BetFact extends StatelessWidget {
  const BetFact({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
