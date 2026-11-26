import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user_role.dart';

extension UserRoleStyle on UserRole {
  IconData get icon => switch (this) {
        UserRole.bettor => Icons.casino_outlined,
        UserRole.bookie => Icons.storefront_outlined,
        UserRole.internal => Icons.shield_outlined,
      };

  /// Each role gets its own colour so it is recognisable at a glance (never colour alone: the label is always shown).
  Color color(ColorScheme scheme) => switch (this) {
        UserRole.bettor => scheme.tertiary,
        UserRole.bookie => scheme.secondary,
        UserRole.internal => scheme.error,
      };
}

/// A small pill with the role's icon and name, e.g. "Bookie".
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role, this.dense = false});
  final UserRole role;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = role.color(theme.colorScheme);
    return Semantics(
      label: 'Role: ${role.label}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 12, vertical: dense ? 4 : 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.chipRadius),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(role.icon, size: dense ? 14 : 16, color: color),
            SizedBox(width: dense ? 4 : 6),
            Text(
              role.label,
              style: theme.textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// The roles worth showing: a bookie can bet too, so the Bettor line is dropped when the account is a bookie.
List<UserRole> displayedRoles(List<UserRole> roles) =>
    roles.contains(UserRole.bookie) ? [for (final r in roles) if (r != UserRole.bettor) r] : roles;

/// The roles of the account side by side.
class RoleBadges extends StatelessWidget {
  const RoleBadges({super.key, required this.roles, this.dense = false});
  final List<UserRole> roles;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final shown = displayedRoles(roles);
    if (shown.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final r in shown) RoleBadge(role: r, dense: dense)],
    );
  }
}

/// "You are a Bookie" card: says which role the account has and what that allows in the app.
class RoleCard extends StatelessWidget {
  const RoleCard({super.key, required this.roles});
  final List<UserRole> roles;

  @override
  Widget build(BuildContext context) {
    final roles = displayedRoles(this.roles);
    if (roles.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final main = roles.first;
    final accent = main.color(scheme);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(main.icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Signed in as',
                        style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                    Text(main.label, style: theme.textTheme.titleLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final role in roles) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(role.icon, size: 18, color: role.color(scheme)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: '${role.label}: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: role.description),
                    ]),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (role != roles.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
