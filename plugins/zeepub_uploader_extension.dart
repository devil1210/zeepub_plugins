import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/inject_dependencies.dart';
import '../../plugins/domain/plugin_extension.dart';
import '../../plugins/domain/plugin_manifest.dart';
import '../presentation/cubit/zeepub_editorial_cubit.dart';
import '../presentation/views/modular/zeepub_uploader_view.dart';

/// Extensión de ZeeTools para el Subidor / Vinculador de EPUBs de ZeePub.
class ZeepubUploaderExtension implements ZeeToolsPluginExtension {
  const ZeepubUploaderExtension();

  @override
  String get id => 'zeepub_uploader';

  @override
  PluginManifest get manifest => const PluginManifest(
        id: 'zeepub_uploader',
        name: 'Subidor de EPUBs',
        version: '1.0.0',
        author: 'ZeePub Team',
        description: 'Validación de metadatos EPUB y subida directa de volúmenes.',
        icon: 'cloud_upload',
      );

  @override
  Widget buildView(BuildContext context, PluginManifest manifest) {
    return BlocProvider(
      create: (_) => getIt<ZeepubEditorialCubit>(),
      child: const ZeepubUploaderView(),
    );
  }
}
