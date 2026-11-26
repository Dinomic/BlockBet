import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/auth_form_widgets.dart';
import '../../../auth/presentation/widgets/role_widgets.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../../../wallet/presentation/bloc/wallets_bloc.dart';
import '../../domain/entities/bet.dart';
import '../bloc/bet_detail_bloc.dart';
import '../widgets/bet_widgets.dart';

class BetDetailPage extends StatelessWidget {
  const BetDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bet')),
      body: SafeArea(
        child: BlocConsumer<BetDetailBloc, BetDetailState>(
          listenWhen: (p, c) => p.doneCount != c.doneCount,
          listener: (context, state) {
            // The place / resolve call only returns once mined: balances changed, refresh them.
            context.read<WalletsBloc>().add(const WalletsRequested());
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.doneMessage ?? 'Done.')));
          },
          builder: (context, state) {
            final bet = state.bet;
            if (bet != null) return _BetBody(bet: bet, state: state);
            if (state.status == BetDetailStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ErrorBanner(
                        title: "Couldn't load this bet",
                        message: state.errorMessage ?? 'Try again in a moment.',
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.read<BetDetailBloc>().add(const BetDetailRequested()),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _BetBody extends StatelessWidget {
  const _BetBody({required this.bet, required this.state});
  final Bet bet;
  final BetDetailState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = context.select((AuthBloc b) => b.state);
    final wallets = context.select((WalletsBloc b) => b.state.wallets);
    final mine = bet.isCreatedBy({for (final w in wallets) w.address.toLowerCase()});

    final hasImage = bet.imageUrl != null &&
        (Uri.tryParse(bet.imageUrl!)?.hasScheme ?? false) &&
        (Uri.tryParse(bet.imageUrl!)?.host.isNotEmpty ?? false);

    return RefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<BetDetailBloc>()..add(const BetDetailRequested());
        await bloc.stream.firstWhere((s) => s.status != BetDetailStatus.loading);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.errorMessage != null) ...[
                  ErrorBanner(title: "Couldn't refresh this bet", message: state.errorMessage!),
                  const SizedBox(height: 12),
                ],
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    child: Image.network(
                      bet.imageUrl!,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(bet.title, style: theme.textTheme.headlineMedium)),
                    const SizedBox(width: 8),
                    BetStatusChip(status: bet.status),
                  ],
                ),
                if (mine) ...[const SizedBox(height: 8), const MineChip()],
                if (bet.description != null) ...[
                  const SizedBox(height: 12),
                  Text(bet.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: BetFact(label: 'Stake per bet', value: '${Wallet.formatWei(bet.stake)} tokens')),
                            Expanded(child: BetFact(label: 'Pool', value: '${Wallet.formatWei(bet.pool)} tokens')),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(child: BetFact(label: 'Bettors', value: '${bet.bettors}')),
                            Expanded(
                              child: BetFact(
                                label: bet.status == BetStatus.open ? 'Closes' : 'Closed',
                                value: bet.closeTime == null ? '—' : _dateTime(bet.closeTime!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _ActionArea(bet: bet, state: state, auth: auth, mine: mine, wallets: wallets),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _dateTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}

/// What the signed-in user can do with this bet, decided by role and by the bet's state.
class _ActionArea extends StatelessWidget {
  const _ActionArea({
    required this.bet,
    required this.state,
    required this.auth,
    required this.mine,
    required this.wallets,
  });
  final Bet bet;
  final BetDetailState state;
  final AuthState auth;
  final bool mine;
  final List<Wallet> wallets;

  @override
  Widget build(BuildContext context) {
    switch (bet.status) {
      case BetStatus.open:
        if (auth.isBettor) return _PlaceBetSection(bet: bet, state: state, wallets: wallets);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionsList(bet: bet),
            const SizedBox(height: 16),
            _Notice(
              icon: Icons.lock_outline_rounded,
              title: 'Only bettors can place bets',
              body: mine
                  ? 'This is your bet. It is open for bettors; you pick the result once betting closes.'
                  : 'You are signed in as ${_roleNames(auth.roles)}, which can’t place bets.',
            ),
          ],
        );
      case BetStatus.closed:
      case BetStatus.caution:
        final canResolve = auth.isBookie && mine;
        if (canResolve) return _ResolveSection(bet: bet, state: state);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionsList(bet: bet),
            const SizedBox(height: 16),
            _Notice(
              icon: bet.status == BetStatus.caution ? Icons.warning_amber_rounded : Icons.hourglass_bottom_rounded,
              title: bet.status == BetStatus.caution ? 'Waiting too long' : 'Betting is closed',
              body: bet.status == BetStatus.caution
                  ? 'The bookie has not picked a result in time. The BlockBet team will step in.'
                  : mine
                      ? 'Your bookie role is required to pick the result, but this account no longer has it.'
                      : 'Waiting for the bookie to pick the winner.',
              isError: bet.status == BetStatus.caution,
            ),
          ],
        );
      case BetStatus.resolved:
        final winner = bet.winningOption;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionsList(bet: bet),
            const SizedBox(height: 16),
            _Notice(
              icon: Icons.emoji_events_outlined,
              title: winner == null ? 'Result in' : 'Winner: ${winner.letter} · ${winner.name}',
              body: 'The pool was split equally between the bettors of the winning option.',
            ),
          ],
        );
      case BetStatus.refunded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OptionsList(bet: bet),
            const SizedBox(height: 16),
            const _Notice(
              icon: Icons.undo_rounded,
              title: 'Refunded',
              body: 'The BlockBet team gave every bettor their stake back.',
            ),
          ],
        );
      case BetStatus.unknown:
        return _OptionsList(bet: bet);
    }
  }

  static String _roleNames(List<UserRole> roles) =>
      roles.isEmpty ? 'a role without betting rights' : roles.map((r) => r.label).join(' + ');
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.body, this.isError = false});
  final IconData icon;
  final String title;
  final String body;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isError ? scheme.error : scheme.tertiary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only list of the options with how many wallets bet on each.
class _OptionsList extends StatelessWidget {
  const _OptionsList({required this.bet});
  final Bet bet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in bet.options) ...[
          _OptionTile(option: o, isWinner: bet.winner == o.letter),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option, this.selected = false, this.isWinner = false, this.onTap});
  final BetOption option;
  final bool selected;
  final bool isWinner;

  /// null = not selectable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highlight = selected || isWinner;
    final accent = isWinner ? scheme.secondary : scheme.tertiary;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: 'Option ${option.letter}, ${option.name}, ${option.bettors} bettors',
      excludeSemantics: true,
      child: Material(
        color: highlight ? accent.withValues(alpha: 0.1) : scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
          side: BorderSide(color: highlight ? accent : scheme.outlineVariant, width: highlight ? 2 : 1.5),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.fieldRadius)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: highlight ? accent : scheme.primaryContainer,
                  child: Text(option.letter,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: highlight ? scheme.surface : scheme.onPrimaryContainer)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(option.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                if (isWinner)
                  Icon(Icons.emoji_events_rounded, color: accent, size: 20)
                else if (selected)
                  Icon(Icons.check_circle_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Text('${option.bettors} ${option.bettors == 1 ? 'bettor' : 'bettors'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bettor: choose an option and a wallet, then pay the bookie's stake.
class _PlaceBetSection extends StatefulWidget {
  const _PlaceBetSection({required this.bet, required this.state, required this.wallets});
  final Bet bet;
  final BetDetailState state;
  final List<Wallet> wallets;

  @override
  State<_PlaceBetSection> createState() => _PlaceBetSectionState();
}

class _PlaceBetSectionState extends State<_PlaceBetSection> {
  String? _option;
  String? _walletAddress;

  Wallet? get _wallet {
    for (final w in widget.wallets) {
      if (w.address == _walletAddress) return w;
    }
    // Default: the first wallet that can pay the stake, else the first one.
    for (final w in widget.wallets) {
      if (w.balanceWei >= widget.bet.stake) return w;
    }
    return widget.wallets.isEmpty ? null : widget.wallets.first;
  }

  Future<void> _submit() async {
    final wallet = _wallet;
    final option = widget.bet.options.where((o) => o.letter == _option).firstOrNull;
    if (wallet == null || option == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Confirm your bet',
        confirmLabel: 'Place bet',
        rows: [
          ('Your pick', '${option.letter} · ${option.name}'),
          ('Stake', '${Wallet.formatWei(widget.bet.stake, maxDecimals: 18)} tokens'),
          ('Paid from', wallet.address),
        ],
        note: 'The stake leaves your wallet now. You can bet only once on each bet.',
      ),
    );
    if (ok != true || !mounted) return;
    context.read<BetDetailBloc>().add(BetPlaced(option: option.letter, fromAddress: wallet.address));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bet = widget.bet;
    final busy = widget.state.isActing;
    final wallet = _wallet;
    final short = wallet != null && wallet.balanceWei < bet.stake;

    // Each account can bet once per bet: after a success there is nothing left to do here.
    if (widget.state.doneCount > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OptionsList(bet: bet),
          const SizedBox(height: 16),
          const _Notice(
            icon: Icons.check_circle_outline_rounded,
            title: 'Your bet is placed',
            body: 'You can bet only once on each bet. Winnings are paid to your wallet when the bookie picks the result.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('PICK AN OPTION',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: scheme.tertiary, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 10),
        for (final o in bet.options) ...[
          _OptionTile(
            option: o,
            selected: _option == o.letter,
            onTap: busy ? null : () => setState(() => _option = o.letter),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        if (widget.wallets.isEmpty)
          const _Notice(
            icon: Icons.account_balance_wallet_outlined,
            title: 'You need a wallet',
            body: 'Create a wallet in the Wallets tab to pay the stake.',
          )
        else ...[
          Text('Pay from',
              style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: wallet?.address,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: [
              for (var i = 0; i < widget.wallets.length; i++)
                DropdownMenuItem(
                  value: widget.wallets[i].address,
                  child: Text(
                    'Wallet ${i + 1} · ${widget.wallets[i].shortAddress} · ${widget.wallets[i].balanceTokens}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: busy ? null : (v) => setState(() => _walletAddress = v),
          ),
          if (short) ...[
            const SizedBox(height: 8),
            Text('This wallet has less than the stake (${Wallet.formatWei(bet.stake)} tokens).',
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
          ],
        ],
        if (widget.state.actionError != null) ...[
          const SizedBox(height: 16),
          ErrorBanner(title: "Couldn't place your bet", message: widget.state.actionError!),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Place bet · ${Wallet.formatWei(bet.stake)} tokens',
          loadingLabel: 'Placing bet…',
          isLoading: busy,
          onPressed: _option == null || wallet == null || short ? null : _submit,
        ),
      ],
    );
  }
}

/// Bookie (owner of the bet): pick the winning option.
class _ResolveSection extends StatefulWidget {
  const _ResolveSection({required this.bet, required this.state});
  final Bet bet;
  final BetDetailState state;

  @override
  State<_ResolveSection> createState() => _ResolveSectionState();
}

class _ResolveSectionState extends State<_ResolveSection> {
  String? _winner;

  Future<void> _submit() async {
    final option = widget.bet.options.where((o) => o.letter == _winner).firstOrNull;
    if (option == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Confirm the result',
        confirmLabel: 'Pick winner',
        rows: [
          ('Winner', '${option.letter} · ${option.name}'),
          ('Pool', '${Wallet.formatWei(widget.bet.pool, maxDecimals: 18)} tokens'),
        ],
        note: 'The pool is paid out to the winners right away. This can’t be undone.',
      ),
    );
    if (ok != true || !mounted) return;
    context.read<BetDetailBloc>().add(BetResolved(option.letter));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = widget.state.isActing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const RoleBadge(role: UserRole.bookie, dense: true),
            const SizedBox(width: 8),
            Expanded(
              child: Text('PICK THE WINNER',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.tertiary, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final o in widget.bet.options) ...[
          _OptionTile(
            option: o,
            selected: _winner == o.letter,
            onTap: busy ? null : () => setState(() => _winner = o.letter),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.bet.status == BetStatus.caution) ...[
          const SizedBox(height: 8),
          const _Notice(
            icon: Icons.warning_amber_rounded,
            title: 'This bet is overdue',
            body: 'Pick the result now so the bettors can be paid.',
            isError: true,
          ),
        ],
        if (widget.state.actionError != null) ...[
          const SizedBox(height: 16),
          ErrorBanner(title: "Couldn't save the result", message: widget.state.actionError!),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Confirm result',
          loadingLabel: 'Paying out…',
          isLoading: busy,
          onPressed: _winner == null ? null : _submit,
        ),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.confirmLabel,
    required this.rows,
    required this.note,
  });
  final String title;
  final String confirmLabel;
  final List<(String, String)> rows;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: muted),
                    const SizedBox(height: 2),
                    SelectableText(value,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            Text(note, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
