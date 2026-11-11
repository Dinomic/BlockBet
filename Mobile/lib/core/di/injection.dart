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
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());

  // Auth - data
  sl.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSourceImpl(sl()));
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(tokenProvider: () => sl<AuthLocalDataSource>().readToken()),
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

  // Auth - presentation (singleton: it owns the app-wide session state)
  sl.registerLazySingleton(
    () => AuthBloc(getSession: sl(), login: sl(), signUp: sl(), logout: sl()),
  );
}
