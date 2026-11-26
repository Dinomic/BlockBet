import 'dart:convert';

import 'package:bbmobile/features/auth/data/models/auth_session_model.dart';
import 'package:bbmobile/features/auth/domain/entities/user_role.dart';
import 'package:bbmobile/features/auth/presentation/widgets/role_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

String jwt(Map<String, Object?> claims) {
  String part(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(claims)}.sig';
}

void main() {
  test('reads the roles claim of the access token, highest privilege first', () {
    final session = AuthSessionModel.fromToken(jwt({
      'email': 'a@b.com',
      'roles': ['ROLE_BETTOR', 'ROLE_BOOKIE'],
    }));

    expect(session.email, 'a@b.com');
    expect(session.roles, [UserRole.bookie, UserRole.bettor]);
  });

  test('a token without roles, or with unknown ones, gives no roles', () {
    expect(AuthSessionModel.fromToken(jwt({'email': 'a@b.com'})).roles, isEmpty);
    expect(AuthSessionModel.fromToken(jwt({'roles': ['ROLE_ALIEN']})).roles, isEmpty);
    expect(AuthSessionModel.fromToken('not-a-jwt').roles, isEmpty);
  });

  test('a bookie is not shown as a bettor too', () {
    expect(displayedRoles([UserRole.bookie, UserRole.bettor]), [UserRole.bookie]);
    expect(displayedRoles([UserRole.internal, UserRole.bookie, UserRole.bettor]), [UserRole.internal, UserRole.bookie]);
    expect(displayedRoles([UserRole.bettor]), [UserRole.bettor]);
  });

  test('login response takes the roles from the access token', () {
    final session = AuthSessionModel.fromJson({
      'accessToken': jwt({'roles': ['ROLE_BETTOR']}),
      'refreshToken': 'r',
    });

    expect(session.roles, [UserRole.bettor]);
    expect(session.refreshToken, 'r');
  });
}
