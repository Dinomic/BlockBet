import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/auth_form_widgets.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../../../wallet/presentation/bloc/wallets_bloc.dart';
import '../../domain/entities/receipt.dart';
import '../bloc/receipts_bloc.dart';

enum _Direction { received, sent, funding }

/// Funding comes from the faucet; otherwise the side that is one of the account's wallets decides.
_Direction _directionOf(Receipt r, Set<String> myAddresses) {
  if (r.type == ReceiptType.funding) return _Direction.funding;
  return myAddresses.contains(r.fromAddress.toLowerCase()) ? _Direction.sent : _Direction.received;
}

class ReceiptsPage extends StatefulWidget {
  const ReceiptsPage({super.key});

  @override
  State<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends State<ReceiptsPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) {
      context.read<ReceiptsBloc>().add(const ReceiptsMoreRequested());
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<ReceiptsBloc>()..add(const ReceiptsRequested());
    await bloc.stream.firstWhere((s) => !s.isRefreshing && s.status != ReceiptsStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    final myAddresses = context.select(
      (WalletsBloc b) => {for (final w in b.state.wallets) w.address.toLowerCase()},
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: SafeArea(
        child: BlocBuilder<ReceiptsBloc, ReceiptsState>(
          builder: (context, state) {
            if (state.status == ReceiptsStatus.loading) return const _LoadingList();
            if (state.status == ReceiptsStatus.failure) {
              return _ErrorView(
                message: state.errorMessage ?? "Couldn't load your transactions.",
                onRetry: () => context.read<ReceiptsBloc>().add(const ReceiptsRequested()),
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: state.receipts.isEmpty
                  ? const _EmptyView()
                  : _ReceiptList(state: state, myAddresses: myAddresses, controller: _scroll),
            );
          },
        ),
      ),
    );
  }
}

class _ReceiptList extends StatelessWidget {
  const _ReceiptList({required this.state, required this.myAddresses, required this.controller});
  final ReceiptsState state;
  final Set<String> myAddresses;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final hasBanner = state.errorMessage != null;
    final receipts = state.receipts;
    return ListView.separated(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      itemCount: receipts.length + (hasBanner ? 1 : 0) + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        var index = i;
        if (hasBanner) {
          if (index == 0) {
            return ErrorBanner(title: "Couldn't load transactions", message: state.errorMessage!);
          }
          index--;
        }
        if (index >= receipts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }
        final receipt = receipts[index];
        return _ReceiptTile(receipt: receipt, direction: _directionOf(receipt, myAddresses));
      },
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt, required this.direction});
  final Receipt receipt;
  final _Direction direction;

  String get _title => switch (direction) {
        _Direction.funding => 'Wallet funded',
        _Direction.sent => 'Sent',
        _Direction.received => 'Received',
      };

  IconData get _icon => switch (direction) {
        _Direction.funding => Icons.water_drop_outlined,
        _Direction.sent => Icons.north_east_rounded,
        _Direction.received => Icons.south_west_rounded,
      };

  /// The other side of the transfer.
  String get _counterparty => switch (direction) {
        _Direction.funding => 'Faucet → ${Wallet.shortenAddress(receipt.toAddress)}',
        _Direction.sent => 'To ${Wallet.shortenAddress(receipt.toAddress)}',
        _Direction.received => 'From ${Wallet.shortenAddress(receipt.fromAddress)}',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _ReceiptDetails(receipt: receipt, title: _title),
        ),
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
                child: Icon(_icon, color: scheme.tertiary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_title,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      _counterparty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: receipt.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (label, color) = switch (status) {
      ReceiptStatus.pending => ('Pending', scheme.onSurfaceVariant),
      ReceiptStatus.confirmed => ('Confirmed', scheme.secondary),
      ReceiptStatus.failed => ('Failed', scheme.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.chipRadius),
      ),
      child: Text(label, style: theme.textTheme.labelMedium?.copyWith(color: color)),
    );
  }
}

class _ReceiptDetails extends StatelessWidget {
  const _ReceiptDetails({required this.receipt, required this.title});
  final Receipt receipt;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fee = receipt.feeWei;
    final rows = <(String, String)>[
      ('Transaction hash', receipt.hash),
      ('From', receipt.fromAddress),
      ('To', receipt.toAddress),
      if (receipt.blockNumber != null) ('Block', receipt.blockNumber.toString()),
      if (fee != null) ('Network fee', '${Wallet.formatWei(fee, maxDecimals: 9)} tokens'),
    ];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.screenPadding, 0, AppTheme.screenPadding, AppTheme.screenPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                _StatusChip(status: receipt.status),
              ],
            ),
            const SizedBox(height: 16),
            for (final (label, value) in rows) ...[
              _DetailRow(label: label, value: value),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              SelectableText(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          tooltip: 'Copy $label',
          icon: const Icon(Icons.copy_rounded, size: 20),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text('$label copied.')));
          },
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
    Widget bar() => Container(
          height: 72,
          decoration: BoxDecoration(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
        );
    return Semantics(
      label: 'Loading transactions',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        children: [bar(), const SizedBox(height: 12), bar(), const SizedBox(height: 12), bar()],
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
        Icon(Icons.receipt_long_outlined, size: 48, color: theme.colorScheme.tertiary),
        const SizedBox(height: 16),
        Text('No transactions yet',
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Transfers and wallet funding will show up here.',
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
            ErrorBanner(title: "Couldn't load your transactions", message: message),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
