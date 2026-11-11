import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_form_widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true; // shared: both password fields toggle together
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggleObscure() => setState(() => _obscure = !_obscure);

  void _submit() {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(SignUpSubmitted(email: _email.text, password: _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.screenPadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final busy = state.isSubmitting;
                  return AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(alignment: Alignment.centerLeft, child: BrandLogo()),
                          const SizedBox(height: 28),
                          Text('Create account', style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(
                            'One account for every market on the network.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          if (state.errorMessage != null) ...[
                            ErrorBanner(
                              title: state.errorTitle ?? "Couldn't create your account",
                              message: state.errorMessage!,
                            ),
                            const SizedBox(height: 16),
                          ],
                          EmailField(
                            controller: _email,
                            validator: Validators.email,
                            enabled: !busy,
                            autovalidateMode: _autovalidate,
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _password,
                            validator: Validators.newPassword,
                            helper: 'Use 8+ characters with a number.',
                            enabled: !busy,
                            obscure: _obscure,
                            onToggleObscure: _toggleObscure,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            autovalidateMode: _autovalidate,
                          ),
                          const SizedBox(height: 16),
                          PasswordField(
                            controller: _confirm,
                            label: 'Confirm password',
                            validator: Validators.confirmPassword(() => _password.text),
                            enabled: !busy,
                            obscure: _obscure,
                            onToggleObscure: _toggleObscure,
                            onSubmitted: _submit,
                            autofillHints: const [AutofillHints.newPassword],
                            autovalidateMode: _autovalidate,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Create account',
                            loadingLabel: 'Creating account…',
                            isLoading: busy,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 12),
                          AuthFooter(
                            prompt: 'Already have an account?',
                            action: 'Log in',
                            onPressed: busy
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(const AuthErrorDismissed());
                                    context.go(Routes.login);
                                  },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
