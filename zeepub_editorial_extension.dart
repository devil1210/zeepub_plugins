import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/inject_dependencies.dart';
import '../plugins/domain/plugin_extension.dart';
import '../plugins/domain/plugin_manifest.dart';
import 'presentation/cubit/zeepub_editorial_cubit.dart';
import 'presentation/views/zeepub_editorial_view.dart';

class ZeepubEditorialExtension implements ZeeToolsPluginExtension {
  const ZeepubEditorialExtension();

  @override
  String get id => 'zeepub_editorial';

  @override
  Widget buildView(BuildContext context, PluginManifest manifest) {
    return BlocProvider(
      create: (_) => getIt<ZeepubEditorialCubit>(),
      child: const ZeepubEditorialView(),
    );
  }
}
