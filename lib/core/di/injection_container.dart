import 'package:get_it/get_it.dart';
import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cms/core/config/app_config.dart' as cfg;
import 'package:cms/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cms/features/auth/domain/repositories/auth_repository.dart';
import 'package:cms/features/auth/domain/usecases/login_usecase.dart';
import 'package:cms/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cms/features/projects/presentation/bloc/project_bloc.dart';
import 'package:cms/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:cms/features/projects/domain/repositories/project_repository.dart';
import 'package:cms/features/projects/data/repositories/project_repository_impl.dart';
import 'package:cms/features/tasks/domain/repositories/task_repository.dart';
import 'package:cms/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:cms/features/purchase_receipts/domain/repositories/purchase_receipt_repository.dart';
import 'package:cms/features/purchase_receipts/data/repositories/purchase_receipt_repository_impl.dart';
import 'package:cms/features/purchase_receipts/presentation/bloc/purchase_receipt_bloc.dart';
import 'package:cms/features/stock_entry/domain/repositories/stock_entry_repository.dart';
import 'package:cms/features/stock_entry/data/repositories/stock_entry_repository_impl.dart';
import 'package:cms/features/stock_entry/presentation/bloc/stock_entry_bloc.dart';
import 'package:cms/features/usage/data/repositories/manpower_usage_repository_impl.dart';
import 'package:cms/features/usage/domain/repositories/manpower_usage_repository.dart';
import 'package:cms/features/usage/presentation/bloc/manpower_usage_bloc.dart';
import 'package:cms/features/usage/data/repositories/equipment_usage_repository_impl.dart';
import 'package:cms/features/usage/domain/repositories/equipment_usage_repository.dart';
import 'package:cms/features/usage/presentation/bloc/equipment_usage_bloc.dart';
import 'package:cms/features/material_requests/domain/repositories/material_request_repository.dart';
import 'package:cms/features/material_requests/data/repositories/material_request_repository_impl.dart';
import 'package:cms/features/material_requests/presentation/bloc/material_request_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Frappe SDK
  final sdk = FrappeSDK(baseUrl: cfg.AppConfig.baseUrl);
  await sdk.initialize(true);
  sl.registerSingleton<FrappeSDK>(sdk);

  // Features - Auth

  // BLoC
  sl.registerFactory(() => AuthBloc(loginUseCase: sl(), authRepository: sl()));
  sl.registerFactory(() => ProjectBloc(projectRepository: sl()));
  sl.registerFactory(() => TaskBloc(taskRepository: sl()));
  sl.registerFactory(() => PurchaseReceiptBloc(repository: sl()));
  sl.registerFactory(() => StockEntryBloc(repository: sl()));
  sl.registerFactory(() => ManpowerUsageBloc(repository: sl()));
  sl.registerFactory(() => EquipmentUsageBloc(repository: sl()));
  sl.registerFactory(() => MaterialRequestBloc(repository: sl()));

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(sl()));
  sl.registerLazySingleton<PurchaseReceiptRepository>(
    () => PurchaseReceiptRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<StockEntryRepository>(
    () => StockEntryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ManpowerUsageRepository>(
    () => ManpowerUsageRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<EquipmentUsageRepository>(
    () => EquipmentUsageRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<MaterialRequestRepository>(
    () => MaterialRequestRepositoryImpl(sl()),
  );
}
