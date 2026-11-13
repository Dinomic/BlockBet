import '../../domain/entities/wallet.dart';

class WalletModel {
  const WalletModel._();

  /// Parses one item of `WalletsGetResponse.wallets`. `privateKey` is deliberately ignored.
  static Wallet fromJson(Map<String, dynamic> json) => Wallet(
        address: json['address'] as String,
        publicKey: (json['publicKey'] as String?) ?? '',
        balanceWei: _parseWei(json['balance']),
      );

  static List<Wallet> listFromJson(dynamic data) {
    final items = data is Map ? data['wallets'] : null;
    if (items is! List) return const [];
    return [for (final e in items) fromJson(Map<String, dynamic>.from(e as Map))];
  }

  /// The API sends wei as a JSON number (can exceed 2^53) — accept num or string.
  static BigInt _parseWei(Object? v) {
    if (v is int) return BigInt.from(v);
    if (v is num) return BigInt.from(v);
    if (v is String) {
      return BigInt.tryParse(v) ?? BigInt.from(double.tryParse(v) ?? 0);
    }
    return BigInt.zero;
  }
}
