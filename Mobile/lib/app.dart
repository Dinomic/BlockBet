import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

class BlockBetApp extends StatefulWidget {
  const BlockBetApp({super.key});

  @override
  State<BlockBetApp> createState() => _BlockBetAppState();
}

class _BlockBetAppState extends State<BlockBetApp> {
  late final AuthBloc _authBloc = sl<AuthBloc>()..add(const AuthStarted());
  late final GoRouter _router = createRouter(_authBloc);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'BlockBet',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: _router,
      ),
    );
  }
}
