import 'package:equatable/equatable.dart';

/// A blockchain wallet owned by the signed-in account.
///
/// Only the public data is modelled on purpose: the API also returns the wallet's
/// private key, which must never be held in (or rendered by) the app.
class Wallet extends Equatable {
  const Wallet({required this.address, required this.publicKey, required this.balanceWei});

  final String address;
  final String publicKey;

  /// Balance in wei (1 token = 10^18 wei).
  final BigInt balanceWei;

  /// Mirrors the backend rule (IBlockBetConstant.MAX_WALLETS_PER_ACCOUNT).
  static const maxPerAccount = 10;

  static final _weiPerToken = BigInt.from(10).pow(18);

  /// Balance as a trimmed decimal string, e.g. `1.5`, `0`, `0.000001`.
  String get balanceTokens => formatWei(balanceWei);

  /// `0x1234…abcd` style short form for lists.
  String get shortAddress => shortenAddress(address);

  static String formatWei(BigInt wei, {int maxDecimals = 6}) {
    final negative = wei.isNegative;
    final abs = negative ? -wei : wei;
    final whole = abs ~/ _weiPerToken;
    final frac = (abs % _weiPerToken).toString().padLeft(18, '0').substring(0, maxDecimals);
    final trimmed = frac.replaceFirst(RegExp(r'0+$'), '');
    final wholeStr = _group(whole.toString());
    return '${negative ? '-' : ''}$wholeStr${trimmed.isEmpty ? '' : '.$trimmed'}';
  }

  static String shortenAddress(String a) =>
      a.length <= 14 ? a : '${a.substring(0, 6)}…${a.substring(a.length - 4)}';

  static String _group(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  @override
  List<Object?> get props => [address, publicKey, balanceWei];
}
