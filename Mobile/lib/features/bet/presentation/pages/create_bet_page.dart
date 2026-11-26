import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/widgets/auth_form_widgets.dart';
import '../../../auth/presentation/widgets/role_widgets.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../../../wallet/presentation/bloc/wallets_bloc.dart';
import '../../domain/entities/bet.dart';
import '../bloc/create_bet_bloc.dart';

enum _Unit {
  minutes('Minutes', 1),
  hours('Hours', 60),
  days('Days', 60 * 24);

  const _Unit(this.label, this.inMinutes);
  final String label;

  /// Length of one unit, in minutes.
  final int inMinutes;
}

/// Bookie only (the route is guarded): create a bet with 2 to 5 options.
class CreateBetPage extends StatefulWidget {
  const CreateBetPage({super.key});

  @override
  State<CreateBetPage> createState() => _CreateBetPageState();
}

class _CreateBetPageState extends State<CreateBetPage> {
  static const _minOptions = 2;
  static const _maxOptions = 5;
  static const _maxDays = 365;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _stake = TextEditingController();
  final _duration = TextEditingController(text: '1');
  final List<TextEditingController> _options = [TextEditingController(), TextEditingController()];
  String? _fromAddress;
  _Unit _unit = _Unit.days;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    final wallets = context.read<WalletsBloc>().state.wallets;
    _fromAddress = wallets.isEmpty ? null : wallets.first.address;
  }

  @override
  void dispose() {
    for (final c in [_title, _description, _imageUrl, _stake, _duration, ..._options]) {
      c.dispose();
    }
    super.dispose();
  }

  String letter(int i) => String.fromCharCode(65 + i);

  void _addOption() {
    if (_options.length >= _maxOptions) return;
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_options.length <= _minOptions) return;
    setState(() => _options.removeAt(i).dispose());
  }

  String? _validateOption(int index, String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Name option ${letter(index)}.';
    if (utf8.encode(value).length > 64) return 'Keep it under 64 characters.';
    final lower = value.toLowerCase();
    for (var i = 0; i < _options.length; i++) {
      if (i != index && _options[i].text.trim().toLowerCase() == lower) {
        return 'Each option needs a different name.';
      }
    }
    return null;
  }

  String? _validateStake(String? v) {
    final wei = Wallet.parseTokens(v ?? '');
    if (wei == null) {
      return (v ?? '').trim().isEmpty ? 'Enter the stake.' : 'Enter a valid amount (up to 18 decimals).';
    }
    if (wei <= BigInt.zero) return 'Stake must be greater than 0.';
    return null;
  }

  String? _validateDuration(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n <= 0) return 'Enter a whole number greater than 0.';
    if (n * _unit.inMinutes > _maxDays * 24 * 60) return 'At most $_maxDays days.';
    return null;
  }

  Future<void> _review() async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;
    final from = _fromAddress;
    if (from == null) return;

    final bet = NewBet(
      fromAddress: from,
      title: _title.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      options: [for (final c in _options) c.text.trim()],
      stakeWei: Wallet.parseTokens(_stake.text)!,
      duration: Duration(minutes: int.parse(_duration.text.trim()) * _unit.inMinutes),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ReviewDialog(bet: bet, durationLabel: '${_duration.text.trim()} ${_unit.label.toLowerCase()}'),
    );
    if (ok != true || !mounted) return;
    context.read<CreateBetBloc>().add(CreateBetSubmitted(bet));
  }

  void _onSuccess(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Bet created. Bettors can join now.')));
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final wallets = context.select((WalletsBloc b) => b.state.wallets);

    return Scaffold(
      appBar: AppBar(title: const Text('Create bet')),
      body: SafeArea(
        child: BlocConsumer<CreateBetBloc, CreateBetState>(
          listenWhen: (p, c) => p.status != c.status && c.status == CreateBetStatus.success,
          listener: (context, _) => _onSuccess(context),
          builder: (context, state) {
            final busy = state.isSubmitting || state.status == CreateBetStatus.success;
            if (wallets.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  child: Text('You need a wallet before you can create a bet. Create one in the Wallets tab.',
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
                        const Align(alignment: Alignment.centerLeft, child: RoleBadge(role: UserRole.bookie)),
                        const SizedBox(height: 16),
                        if (state.errorMessage != null) ...[
                          ErrorBanner(title: "Couldn't create the bet", message: state.errorMessage!),
                          const SizedBox(height: 16),
                        ],
                        Text('Created from',
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
                                child: Text('Wallet ${i + 1} · ${wallets[i].shortAddress} · ${wallets[i].balanceTokens}',
                                    overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: busy ? null : (v) => setState(() => _fromAddress = v),
                        ),
                        const SizedBox(height: 6),
                        Text('Only this wallet can pick the result later.',
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'Title',
                          controller: _title,
                          enabled: !busy,
                          autovalidateMode: _autovalidate,
                          textInputAction: TextInputAction.next,
                          helper: 'E.g. “Arsenal vs MU”.',
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Enter a title.';
                            if (t.length > 128) return 'Title must be at most 128 characters.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'Description (optional)',
                          controller: _description,
                          enabled: !busy,
                          autovalidateMode: _autovalidate,
                          textInputAction: TextInputAction.next,
                          validator: Validators.optionalMaxLength(1024, 'Description'),
                        ),
                        const SizedBox(height: 16),
                        LabeledField(
                          label: 'Image link (optional)',
                          controller: _imageUrl,
                          enabled: !busy,
                          autovalidateMode: _autovalidate,
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                          validator: (v) => Validators.avatarUrl(v)?.replaceFirst('Avatar URL', 'Image link'),
                        ),
                        const SizedBox(height: 24),
                        Text('OPTIONS',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.tertiary, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('Between $_minOptions and $_maxOptions. Bettors pick one of them.',
                            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 12),
                        for (var i = 0; i < _options.length; i++) ...[
                          LabeledField(
                            label: 'Option ${letter(i)}',
                            controller: _options[i],
                            enabled: !busy,
                            autovalidateMode: _autovalidate,
                            textInputAction: TextInputAction.next,
                            validator: (v) => _validateOption(i, v),
                            suffix: _options.length > _minOptions
                                ? IconButton(
                                    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                                    tooltip: 'Remove option ${letter(i)}',
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                    onPressed: busy ? null : () => _removeOption(i),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_options.length < _maxOptions)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: busy ? null : _addOption,
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: const Text('Add option'),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text('RULES',
                            style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.tertiary, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'Stake per bettor (tokens)',
                          controller: _stake,
                          enabled: !busy,
                          autovalidateMode: _autovalidate,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          helper: 'Every bettor pays exactly this amount, once.',
                          validator: _validateStake,
                        ),
                        const SizedBox(height: 16),
                        Text('Bets are accepted for',
                            style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _duration,
                                enabled: !busy,
                                autovalidateMode: _autovalidate,
                                keyboardType: TextInputType.number,
                                validator: _validateDuration,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<_Unit>(
                                initialValue: _unit,
                                decoration: const InputDecoration(),
                                items: [
                                  for (final u in _Unit.values) DropdownMenuItem(value: u, child: Text(u.label)),
                                ],
                                onChanged: busy ? null : (u) => setState(() => _unit = u ?? _unit),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        PrimaryButton(
                          label: 'Review bet',
                          loadingLabel: 'Creating…',
                          isLoading: busy,
                          onPressed: _review,
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

class _ReviewDialog extends StatelessWidget {
  const _ReviewDialog({required this.bet, required this.durationLabel});
  final NewBet bet;
  final String durationLabel;

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
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return AlertDialog(
      title: const Text('Create this bet?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row('Title', bet.title),
            row('Options', [for (var i = 0; i < bet.options.length; i++) '${String.fromCharCode(65 + i)} · ${bet.options[i]}'].join('\n')),
            row('Stake per bettor', '${Wallet.formatWei(bet.stakeWei, maxDecimals: 18)} tokens'),
            row('Betting open for', durationLabel),
            Text(
              'Once created, the options and rules can’t be changed. You pick the winner after betting closes.',
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
          child: const Text('Create'),
        ),
      ],
    );
  }
}
