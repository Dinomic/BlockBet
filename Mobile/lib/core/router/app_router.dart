import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../di/injection.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/home/presentation/pages/app_shell.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/wallet/presentation/bloc/wallets_bloc.dart';
import '../../features/wallet/presentation/pages/wallets_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'routes.dart';

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _StreamListenable(authBloc.stream),
    redirect: (context, state) {
      final status = authBloc.state.status;
      final loc = state.matchedLocation;
      final onAuthPage = loc == Routes.login || loc == Routes.signUp;

      switch (status) {
        case AuthStatus.unknown:
          return loc == Routes.splash ? null : Routes.splash;
        case AuthStatus.unauthenticated:
          return onAuthPage ? null : Routes.login;
        case AuthStatus.authenticated:
          return (onAuthPage || loc == Routes.splash) ? Routes.home : null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpPage()),
      StatefulShellRoute.indexedStack(
        // Wallets are shared by Home (summary) and the Wallets tab.
        builder: (_, _, shell) => BlocProvider(
          create: (_) => sl<WalletsBloc>()..add(const WalletsRequested()),
          child: AppShell(navigationShell: shell),
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, _) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.wallets, builder: (_, _) => const WalletsPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.profile,
              builder: (_, _) => BlocProvider(
                create: (_) => sl<ProfileBloc>()..add(const ProfileRequested()),
                child: const ProfilePage(),
              ),
            ),
          ]),
        ],
      ),
    ],
  );
}

class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
