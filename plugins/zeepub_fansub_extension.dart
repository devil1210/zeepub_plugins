import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/inject_dependencies.dart';
import '../../plugins/domain/plugin_extension.dart';
import '../../plugins/domain/plugin_manifest.dart';
import '../presentation/cubit/zeepub_editorial_cubit.dart';
import '../presentation/views/modular/zeepub_fansub_view.dart';

/// Extensión de ZeeTools para el Editor de Fansub y Equipos de ZeePub.
class ZeepubFansubExtension implements ZeeToolsPluginExtension {
  const ZeepubFansubExtension();

  @override
  String get id => 'zeepub_fansub';

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'zeepub_fansub',
        name: 'Editor de Fansub',
        version: '1.0.0',
        author: 'ZeePub Team',
        description: 'Administración de roles, miembros y equipos de trabajo.',
        icon: 'groups',
      );

  @override
  Widget buildView(BuildContext context, PluginManifest manifest) {
    return BlocProvider(
      create: (_) => getIt<ZeepubEditorialCubit>(),
      child: const ZeepubFansubView(),
    );
  }
}
