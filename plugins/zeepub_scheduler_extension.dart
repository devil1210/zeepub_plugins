import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/inject_dependencies.dart';
import '../../plugins/domain/plugin_extension.dart';
import '../../plugins/domain/plugin_manifest.dart';
import '../presentation/cubit/zeepub_editorial_cubit.dart';
import '../presentation/views/modular/zeepub_scheduler_view.dart';

/// Extensión de ZeeTools para el Programador de Publicaciones de ZeePub.
class ZeepubSchedulerExtension implements ZeeToolsPluginExtension {
  const ZeepubSchedulerExtension();

  @override
  String get id => 'zeepub_scheduler';

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'zeepub_scheduler',
        name: 'Programador de Publicaciones',
        version: '1.0.0',
        author: 'ZeePub Team',
        description: 'Programación de publicaciones automáticas en canales y redes.',
        icon: 'calendar',
      );

  @override
  Widget buildView(BuildContext context, PluginManifest manifest) {
    return BlocProvider(
      create: (_) => getIt<ZeepubEditorialCubit>(),
      child: const ZeepubSchedulerView(),
    );
  }
}
