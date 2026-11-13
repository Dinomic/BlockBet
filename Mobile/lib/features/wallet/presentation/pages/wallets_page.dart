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
      floatingActionButton: const _CreateWalletButton(),
      body: SafeArea(
        child: BlocConsumer<WalletsBloc, WalletsState>(
          listenWhen: (p, c) => p.createCount != c.createCount || p.createError != c.createError,
          listener: (context, state) {
            final text = state.createError ?? 'Wallet created.';
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(text)));
          },
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
      // Bottom padding keeps the last tile clear of the floating button.
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding, 4, AppTheme.screenPadding, 96,
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
                '$count of ${Wallet.maxPerAccount} wallets',
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

class _CreateWalletButton extends StatelessWidget {
  const _CreateWalletButton();

  Future<void> _onPressed(BuildContext context) async {
    final bloc = context.read<WalletsBloc>();
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _CreateWalletDialog(),
    );
    if (password != null) bloc.add(WalletCreated(password));
  }

  void _showLimitMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('You can have at most ${Wallet.maxPerAccount} wallets per account.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocBuilder<WalletsBloc, WalletsState>(
      buildWhen: (p, c) =>
          p.status != c.status || p.isCreating != c.isCreating || p.wallets.length != c.wallets.length,
      builder: (context, state) {
        if (state.status != WalletsStatus.loaded) return const SizedBox.shrink();
        final muted = state.isCreating || state.limitReached;
        return Tooltip(
          message: state.limitReached ? 'Wallet limit reached (${Wallet.maxPerAccount})' : '',
          child: FloatingActionButton.extended(
            // At the limit the button stays tappable so it can explain why nothing happens.
            onPressed: state.isCreating
                ? null
                : state.limitReached
                    ? () => _showLimitMessage(context)
                    : () => _onPressed(context),
            // Opaque (blended) so list content never shows through the button.
            backgroundColor: muted
                ? Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.12), scheme.surface)
                : scheme.primary,
            foregroundColor: muted ? scheme.onSurfaceVariant : scheme.onPrimary,
            elevation: muted ? 0 : 2,
            icon: state.isCreating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.add_rounded),
            label: Text(
              state.isCreating
                  ? 'Creating…'
                  : state.limitReached
                      ? 'Limit reached'
                      : 'New wallet',
            ),
          ),
        );
      },
    );
  }
}

class _CreateWalletDialog extends StatefulWidget {
  const _CreateWalletDialog();

  @override
  State<_CreateWalletDialog> createState() => _CreateWalletDialogState();
}

class _CreateWalletDialogState extends State<_CreateWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('New wallet'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a password to protect this wallet. New wallets are funded automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              label: 'Wallet password',
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmitted: _submit,
              validator: (v) => (v == null || v.isEmpty) ? 'Enter a wallet password.' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
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
