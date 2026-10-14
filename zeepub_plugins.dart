import '/inject_dependencies.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeetools/features/plugins/data/plugin_registry.dart';

import 'data/datasources/zeepub_api_client.dart';
import 'data/repositories/zeepub_editorial_repository.dart';
import 'plugins/zeepub_catalog_extension.dart';
import 'plugins/zeepub_fansub_extension.dart';
import 'plugins/zeepub_scheduler_extension.dart';
import 'plugins/zeepub_uploader_extension.dart';
import 'presentation/cubit/zeepub_editorial_cubit.dart';

export 'plugins/zeepub_catalog_extension.dart';
export 'plugins/zeepub_fansub_extension.dart';
export 'plugins/zeepub_scheduler_extension.dart';
export 'plugins/zeepub_uploader_extension.dart';

/// Registra todos los complementos y dependencias de ZeePub en ZeeTools.
void registerZeepubPlugins(PluginRegistry registry) {
  // 1. Inyectar dependencias del cubit y API si no están registradas
  if (!getIt.isRegistered<ZeepubApiClient>()) {
    getIt.registerLazySingleton<ZeepubApiClient>(() => ZeepubApiClient());
  }
  if (!getIt.isRegistered<ZeepubEditorialRepository>()) {
    getIt.registerLazySingleton<ZeepubEditorialRepository>(
      () => ZeepubEditorialRepository(
        client: getIt<ZeepubApiClient>(),
        prefs: getIt<SharedPreferences>(),
      ),
    );
  }
  if (!getIt.isRegistered<ZeepubEditorialCubit>()) {
    getIt.registerFactory<ZeepubEditorialCubit>(
      () => ZeepubEditorialCubit(repository: getIt<ZeepubEditorialRepository>()),
    );
  }

  // 2. Registrar los 4 complementos modulares
  registry.register(const ZeepubCatalogExtension());
  registry.register(const ZeepubFansubExtension());
  registry.register(const ZeepubSchedulerExtension());
  registry.register(const ZeepubUploaderExtension());
}
