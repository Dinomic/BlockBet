/// What an account may do in the betting flow. Mirrors the backend `AccountRole`.
///
/// Every account starts as a bettor; BOOKIE and INTERNAL are granted by hand on the server.
enum UserRole {
  bettor('Bettor', 'Bet on the bets that bookies create.'),
  bookie('Bookie', 'Create bets and pick the winning option once betting is closed.'),
  internal('Internal', 'BlockBet team: handles bets that were not resolved in time.');

  const UserRole(this.label, this.description);

  final String label;
  final String description;

  /// Parses a JWT `roles` entry such as `ROLE_BOOKIE`; null for an unknown role.
  static UserRole? fromClaim(Object? claim) {
    if (claim is! String) return null;
    return switch (claim.toUpperCase().replaceFirst('ROLE_', '')) {
      'BETTOR' => UserRole.bettor,
      'BOOKIE' => UserRole.bookie,
      'INTERNAL' => UserRole.internal,
      _ => null,
    };
  }

  /// Highest-privilege first, so the first role of a list is the one to headline.
  static List<UserRole> sorted(Iterable<UserRole> roles) =>
      (roles.toSet().toList()..sort((a, b) => b.index.compareTo(a.index)));
}
