import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/views/zeepub_editorial_view.dart';
import '/inject_dependencies.dart';

abstract final class ZeepubEditorialRoute {
  static const name = 'zeepub_editorial';
  static const path = 'zeepub-editorial';

  static GoRoute get route => GoRoute(
        name: name,
        path: path,
        builder: (_, _) => BlocProvider(
          create: (_) => getIt<ZeepubEditorialCubit>(),
          child: const ZeepubEditorialView(),
        ),
      );
}
