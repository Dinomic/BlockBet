/// Copy follows design/DESIGN.md "Validation and error messages".
class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email.';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'Enter your password.' : null;

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.length < 8 || !v.contains(RegExp(r'\d'))) {
      return 'Use at least 8 characters with a number.';
    }
    return null;
  }

  /// Optional text field limited to [max] characters (matches the backend limits).
  static String? Function(String?) optionalMaxLength(int max, String label) {
    return (value) => (value?.trim().length ?? 0) > max
        ? '$label must be at most $max characters.'
        : null;
  }

  /// Optional ISO 3166-1 alpha-2 country code, e.g. `VN`.
  static String? nationality(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    return RegExp(r'^[A-Za-z]{2}$').hasMatch(v) ? null : 'Use a 2-letter country code, e.g. VN.';
  }

  /// Optional http(s) URL up to 512 characters.
  static String? avatarUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > 512) return 'Avatar URL must be at most 512 characters.';
    final uri = Uri.tryParse(v);
    final ok = uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    return ok ? null : 'Enter a valid http(s) link.';
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Confirm your password.';
      if (value != original()) return 'Passwords do not match.';
      return null;
    };
  }
}
