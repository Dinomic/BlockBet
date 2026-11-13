import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/auth_form_widgets.dart';
import '../../data/models/profile_model.dart';
import '../../domain/entities/profile.dart';
import '../bloc/profile_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listenWhen: (prev, curr) => prev.saveCount != curr.saveCount,
          listener: (context, _) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('Profile updated.')));
          },
          builder: (context, state) {
            final profile = state.profile;
            if (profile != null) return _ProfileForm(profile: profile, state: state);
            if (state.status == ProfileStatus.failure) {
              return _LoadError(message: state.errorMessage ?? "Couldn't load your profile.");
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorBanner(title: "Couldn't load your profile", message: message),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.read<ProfileBloc>().add(const ProfileRequested()),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.profile, required this.state});
  final Profile profile;
  final ProfileState state;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _displayName;
  late final TextEditingController _avatarUrl;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _nationality;
  late final TextEditingController _dateOfBirth;
  Gender? _gender;
  DateTime? _dob;

  /// What the server currently has; the Save button only enables once something differs.
  late Profile _saved;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.profile.email);
    _displayName = TextEditingController();
    _avatarUrl = TextEditingController();
    _phone = TextEditingController();
    _address = TextEditingController();
    _nationality = TextEditingController();
    _dateOfBirth = TextEditingController();
    _load(widget.profile);
    for (final c in [_displayName, _avatarUrl, _phone, _address, _nationality]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void didUpdateWidget(_ProfileForm old) {
    super.didUpdateWidget(old);
    // A successful save returns the stored profile: re-sync so the form is "clean" again.
    if (old.state.saveCount != widget.state.saveCount) {
      _load(widget.profile);
    }
  }

  @override
  void dispose() {
    for (final c in [_email, _displayName, _avatarUrl, _phone, _address, _nationality, _dateOfBirth]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Profile p) {
    _saved = p;
    _displayName.text = p.displayName ?? '';
    _avatarUrl.text = p.avatarUrl ?? '';
    _phone.text = p.phone ?? '';
    _address.text = p.address ?? '';
    _nationality.text = p.nationality ?? '';
    _gender = p.gender;
    _dob = p.dateOfBirth;
    _dateOfBirth.text = _dob == null ? '' : ProfileModel.formatDate(_dob!);
  }

  void _onChanged() => setState(() {});

  static bool _sameDay(DateTime? a, DateTime? b) =>
      a == null || b == null ? a == b : a.year == b.year && a.month == b.month && a.day == b.day;

  /// Only fields that were edited to a non-empty, different value are sent.
  /// The backend cannot clear a field, so emptying one is not an update.
  ProfileUpdate _diff() {
    String? changed(TextEditingController c, String? original, {bool upper = false}) {
      var v = c.text.trim();
      if (upper) v = v.toUpperCase();
      return v.isEmpty || v == (original ?? '') ? null : v;
    }

    return ProfileUpdate(
      displayName: changed(_displayName, _saved.displayName),
      avatarUrl: changed(_avatarUrl, _saved.avatarUrl),
      phone: changed(_phone, _saved.phone),
      address: changed(_address, _saved.address),
      nationality: changed(_nationality, _saved.nationality, upper: true),
      dateOfBirth: _dob != null && !_sameDay(_dob, _saved.dateOfBirth) ? _dob : null,
      gender: _gender != null && _gender != _saved.gender ? _gender : null,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      _dob = picked;
      _dateOfBirth.text = ProfileModel.formatDate(picked);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final update = _diff();
    if (update.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<ProfileBloc>().add(ProfileSaved(update));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saving = widget.state.isSaving;
    final canSave = !saving && !_diff().isEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.screenPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(profile: _saved, avatarUrl: _avatarUrl.text.trim()),
                const SizedBox(height: 24),
                if (widget.state.errorMessage != null) ...[
                  ErrorBanner(title: "Couldn't save your profile", message: widget.state.errorMessage!),
                  const SizedBox(height: 16),
                ],
                const _SectionTitle('Personal'),
                LabeledField(
                  label: 'Email',
                  controller: _email,
                  validator: (_) => null,
                  enabled: false,
                  helper: 'Your email can’t be changed.',
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Display name',
                  controller: _displayName,
                  validator: Validators.optionalMaxLength(64, 'Display name'),
                  enabled: !saving,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Date of birth',
                  controller: _dateOfBirth,
                  validator: (_) => null,
                  enabled: !saving,
                  readOnly: true,
                  onTap: _pickDate,
                  suffix: const Icon(Icons.calendar_today_outlined, size: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gender',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                SegmentedButton<Gender>(
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: [
                    for (final g in Gender.values) ButtonSegment(value: g, label: Text(g.label)),
                  ],
                  selected: {?_gender},
                  onSelectionChanged: saving
                      ? null
                      : (s) => setState(() => _gender = s.isEmpty ? null : s.first),
                ),
                const _SectionTitle('Contact'),
                LabeledField(
                  label: 'Phone',
                  controller: _phone,
                  validator: Validators.optionalMaxLength(16, 'Phone'),
                  enabled: !saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Address',
                  controller: _address,
                  validator: Validators.optionalMaxLength(256, 'Address'),
                  enabled: !saving,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Country code',
                  controller: _nationality,
                  validator: Validators.nationality,
                  enabled: !saving,
                  helper: '2-letter code, e.g. VN.',
                  textInputAction: TextInputAction.next,
                ),
                const _SectionTitle('Avatar'),
                LabeledField(
                  label: 'Avatar URL',
                  controller: _avatarUrl,
                  validator: Validators.avatarUrl,
                  enabled: !saving,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _save,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Save changes',
                  loadingLabel: 'Saving…',
                  isLoading: saving,
                  onPressed: canSave ? _save : null,
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  onPressed: saving
                      ? null
                      : () => context.read<AuthBloc>().add(const LogoutRequested()),
                  label: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 14),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.tertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.avatarUrl});
  final Profile profile;
  final String avatarUrl;

  String get _title =>
      (profile.displayName?.trim().isNotEmpty ?? false) ? profile.displayName!.trim() : profile.email;

  String get _initial => _title.isEmpty ? '?' : _title.characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final uri = Uri.tryParse(avatarUrl);
    final hasImage = uri != null && uri.hasScheme && uri.host.isNotEmpty;

    return Column(
      children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: scheme.primaryContainer,
          foregroundImage: hasImage ? NetworkImage(avatarUrl) : null,
          // A broken link falls back to the initial instead of throwing.
          onForegroundImageError: hasImage ? (_, _) {} : null,
          child: Text(_initial, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        Text(_title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        if (_title != profile.email) ...[
          const SizedBox(height: 2),
          Text(
            profile.email,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
