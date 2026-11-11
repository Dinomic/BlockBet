import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_form_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  // Validate on submit; afterwards re-validate as the user edits so errors clear.
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(LoginSubmitted(email: _email.text, password: _password.text));
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
                          Text('Welcome back', style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Log in to place and track your bets.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          if (state.errorMessage != null) ...[
                            ErrorBanner(
                              title: state.errorTitle ?? "Couldn't log you in",
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
                            validator: Validators.loginPassword,
                            enabled: !busy,
                            obscure: _obscure,
                            onToggleObscure: () => setState(() => _obscure = !_obscure),
                            onSubmitted: _submit,
                            autofillHints: const [AutofillHints.password],
                            autovalidateMode: _autovalidate,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Log in',
                            loadingLabel: 'Logging in…',
                            isLoading: busy,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 12),
                          AuthFooter(
                            prompt: 'New to BlockBet?',
                            action: 'Create account',
                            onPressed: busy
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(const AuthErrorDismissed());
                                    context.go(Routes.signUp);
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
