import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/widgets/auth_form_widgets.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/usecases/transfer_tokens.dart';
import '../bloc/transfer_bloc.dart';
import '../bloc/wallets_bloc.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key, this.initialFrom});

  /// Address of the wallet to preselect (when opened from a wallet tile).
  final String? initialFrom;

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _to = TextEditingController();
  final _amount = TextEditingController();
  String? _fromAddress;
  String? _attemptSignature;
  String? _attemptKey;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final wallets = context.read<WalletsBloc>().state.wallets;
    final preferred = wallets.where((w) => w.address == widget.initialFrom);
    _fromAddress = preferred.isNotEmpty ? preferred.first.address : (wallets.isNotEmpty ? wallets.first.address : null);
  }

  @override
  void dispose() {
    _to.dispose();
    _amount.dispose();
    super.dispose();
  }

  Wallet? _selected(List<Wallet> wallets) {
    for (final w in wallets) {
      if (w.address == _fromAddress) return w;
    }
    return null;
  }

  String? _validateTo(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter the recipient address.';
    if (!Wallet.isValidAddress(value)) return 'Enter a valid address (0x followed by 40 characters).';
    if (value.toLowerCase() == _fromAddress?.toLowerCase()) return "You can't send to the same wallet.";
    return null;
  }

  String? _validateAmount(String? v, Wallet? from) {
    final wei = Wallet.parseTokens(v ?? '');
    if (wei == null) return (v ?? '').trim().isEmpty ? 'Enter an amount.' : 'Enter a valid amount (up to 18 decimals).';
    if (wei <= BigInt.zero) return 'Amount must be greater than 0.';
    if (from != null && wei > from.balanceWei) return 'Amount is more than the wallet balance.';
    return null;
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    setState(() => _to.text = text);
  }

  Future<void> _review(List<Wallet> wallets) async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;
    final from = _selected(wallets);
    if (from == null) return;
    final to = _to.text.trim();
    final amountWei = Wallet.parseTokens(_amount.text)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(from: from, to: to, amountWei: amountWei),
    );
    if (confirmed != true || !mounted) return;

    // One key per distinct transfer: re-submitting the same details after a timeout reuses it, so the
    // server can recognise the retry and not send the tokens twice. Changing any detail starts a new one.
    final signature = '${from.address}|$to|$amountWei';
    if (_attemptSignature != signature) {
      _attemptSignature = signature;
      _attemptKey = _newIdempotencyKey();
    }
    context.read<TransferBloc>().add(TransferSubmitted(
          TransferParams(
            fromAddress: from.address,
            toAddress: to,
            amountWei: amountWei,
            idempotencyKey: _attemptKey!,
          ),
        ));
  }

  static String _newIdempotencyKey() {
    final random = Random.secure();
    return List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  void _onSuccess(BuildContext context) {
    final wallets = context.read<WalletsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    // The transfer is only broadcast: refresh now, and again once a block has probably been mined.
    wallets.add(const WalletsRequested());
    Timer(const Duration(seconds: 8), () {
      if (!wallets.isClosed) wallets.add(const WalletsRequested());
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Transfer sent. Balances update once it is confirmed.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wallets = context.select((WalletsBloc b) => b.state.wallets);
    final selected = _selected(wallets);

    return Scaffold(
      appBar: AppBar(title: const Text('Send tokens')),
      body: SafeArea(
        child: BlocConsumer<TransferBloc, TransferState>(
          listenWhen: (p, c) => p.status != c.status && c.status == TransferStatus.success,
          listener: (context, _) => _onSuccess(context),
          builder: (context, state) {
            final busy = state.isSubmitting || state.status == TransferStatus.success;
            if (wallets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  child: Text('You need a wallet before you can send tokens.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.screenPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _autovalidate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.errorMessage != null) ...[
                          ErrorBanner(title: "Couldn't send tokens", message: state.errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        Text('From',
                            style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _fromAddress,
                          isExpanded: true,
                          decoration: const InputDecoration(),
                          items: [
                            for (var i = 0; i < wallets.length; i++)
                              DropdownMenuItem(
                                value: wallets[i].address,
                                child: Text(
                                  'Wallet ${i + 1} · ${wallets[i].shortAddress} · ${wallets[i].balanceTokens}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: busy
                              ? null
                              : (v) {
                                  setState(() => _fromAddress = v);
                                  context.read<TransferBloc>().add(const TransferErrorDismissed());
                                },
                        ),
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'To (wallet address)',
                          controller: _to,
                          validator: _validateTo,
                          enabled: !busy,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.next,
                          autovalidateMode: _autovalidate,
                          suffix: IconButton(
                            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                            tooltip: 'Paste address',
                            icon: const Icon(Icons.content_paste_rounded, size: 20),
                            onPressed: busy ? null : _paste,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'Amount (tokens)',
                          controller: _amount,
                          validator: (v) => _validateAmount(v, selected),
                          enabled: !busy,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.done,
                          autovalidateMode: _autovalidate,
                          onSubmitted: () => _review(wallets),
                          helper: selected == null
                              ? null
                              : 'Available: ${selected.balanceTokens} tokens. The network fee is paid from the same wallet.',
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Review transfer',
                          loadingLabel: 'Sending…',
                          isLoading: busy,
                          onPressed: () => _review(wallets),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({required this.from, required this.to, required this.amountWei});
  final Wallet from;
  final String to;
  final BigInt amountWei;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: muted),
              const SizedBox(height: 2),
              SelectableText(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return AlertDialog(
      title: const Text('Confirm transfer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row('Amount', '${Wallet.formatWei(amountWei, maxDecimals: 18)} tokens'),
            row('From', from.address),
            row('To', to),
            Text(
              'Transfers can’t be undone. Check the recipient address carefully.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Send'),
        ),
      ],
    );
  }
}
