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

  static String? Function(String?) confirmPassword(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Confirm your password.';
      if (value != original()) return 'Passwords do not match.';
      return null;
    };
  }
}
