import 'package:flutter/material.dart';

/// Text field with the label above the field (not floating), per design spec.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    required this.validator,
    this.helper,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.suffix,
    this.onSubmitted,
    this.autovalidateMode,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final String? helper;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final VoidCallback? onSubmitted;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          autovalidateMode: autovalidateMode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: (_) => onSubmitted?.call(),
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(suffixIcon: suffix),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    required this.validator,
    this.enabled = true,
    this.autovalidateMode,
  });
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: 'Email',
      controller: controller,
      validator: validator,
      enabled: enabled,
      autovalidateMode: autovalidateMode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
    );
  }
}

/// Visibility is owned by the page so both sign-up fields toggle together.
class PasswordField extends StatelessWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.validator,
    required this.obscure,
    required this.onToggleObscure,
    this.label = 'Password',
    this.helper,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.autofillHints,
    this.autovalidateMode,
  });
  final TextEditingController controller;
  final String? Function(String?) validator;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String label;
  final String? helper;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final Iterable<String>? autofillHints;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return LabeledField(
      label: label,
      controller: controller,
      validator: validator,
      helper: helper,
      enabled: enabled,
      obscureText: obscure,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      autovalidateMode: autovalidateMode,
      suffix: IconButton(
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        tooltip: obscure ? 'Show password' : 'Hide password',
        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: enabled ? onToggleObscure : null,
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.error),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(message, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
    this.isLoading = false,
  });
  final String label;
  final String loadingLabel;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 10),
                Text(loadingLabel),
              ],
            )
          : Text(label),
    );
  }
}

/// "New to BlockBet? Create account" style footer.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key, required this.prompt, required this.action, required this.onPressed});
  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}
