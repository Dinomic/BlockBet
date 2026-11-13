import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_session.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/sign_up.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/wallet/data/datasources/wallet_remote_data_source.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/get_wallets.dart';
import '../../features/wallet/presentation/bloc/wallets_bloc.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

  // Auth - data
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      tokenProvider: () => sl<AuthLocalDataSource>().readToken(),
      refreshTokenProvider: () => sl<AuthLocalDataSource>().readRefreshToken(),
      onTokensRefreshed: (access, refresh) =>
          sl<AuthLocalDataSource>().saveTokens(accessToken: access, refreshToken: refresh),
      // Refresh token rejected by the server: drop the session and go back to login.
      onSessionExpired: () async => sl<AuthBloc>().add(const LogoutRequested()),
    ),
  );
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: sl(), local: sl()),
  );

  // Auth - domain
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => SignUp(sl()));
  sl.registerLazySingleton(() => GetSession(sl()));
  sl.registerLazySingleton(() => Logout(sl()));

  // Profile
  sl.registerLazySingleton<ProfileRemoteDataSource>(() => ProfileRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepositoryImpl(remote: sl()));
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  // Factory: each visit to the profile page starts from a fresh load.
  sl.registerFactory(() => ProfileBloc(getProfile: sl(), updateProfile: sl()));

  // Wallet
  sl.registerLazySingleton<WalletRemoteDataSource>(() => WalletRemoteDataSourceImpl(sl()));
  sl.registerLazySingleton<WalletRepository>(() => WalletRepositoryImpl(remote: sl()));
  sl.registerLazySingleton(() => GetWallets(sl()));
  sl.registerFactory(() => WalletsBloc(getWallets: sl()));

  // Auth - presentation (singleton: it owns the app-wide session state)
  sl.registerLazySingleton(
    () => AuthBloc(getSession: sl(), login: sl(), signUp: sl(), logout: sl()),
  );
}
