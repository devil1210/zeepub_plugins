import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/zeepub_editorial_cubit.dart';
import '../../cubit/zeepub_editorial_state.dart';
import '../widgets/workgroup_detail_view.dart';
import '../widgets/workgroups_tab.dart';
import '../widgets/zeepub_server_config_dialog.dart';

/// Vista modular del Editor de Fansub y Equipos de ZeePub.
///
/// Permite gestionar los grupos de traducción, editores, correctores,
/// roles y auditoría de créditos por volumen.
class ZeepubFansubView extends StatefulWidget {
  const ZeepubFansubView({super.key});

  @override
  State<ZeepubFansubView> createState() => _ZeepubFansubViewState();
}

class _ZeepubFansubViewState extends State<ZeepubFansubView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ZeepubEditorialCubit>();
      if (cubit.state.workgroups.isEmpty) {
        cubit.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<ZeepubEditorialCubit, ZeepubEditorialState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: cs.error,
              action: SnackBarAction(
                label: 'OK',
                textColor: cs.onError,
                onPressed: () => context.read<ZeepubEditorialCubit>().clearNotifications(),
              ),
            ),
          );
          context.read<ZeepubEditorialCubit>().clearNotifications();
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green.shade700,
            ),
          );
          context.read<ZeepubEditorialCubit>().clearNotifications();
        }
      },
      builder: (context, state) {
        final cubit = context.read<ZeepubEditorialCubit>();

        // Navigation: Workgroup Detail (Nivel 2)
        if (state.activeWorkgroupDetail != null) {
          return WorkgroupDetailView(
            detail: state.activeWorkgroupDetail!,
            initialTab: state.workgroupDetailInitialTab,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.groups_rounded, color: Color(0xFF818CF8)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Editor de Fansub', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(
                      'Equipos traductores y créditos colaborativos (${state.workgroups.length} grupos)',
                      style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Ajustes del Servidor',
                onPressed: () => showZeepubServerConfigDialog(
                  context,
                  currentUrl: state.baseUrl,
                  currentTgId: state.telegramUserId,
                  currentScale: state.coverScale,
                  cubit: cubit,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: const ZeepubWorkgroupsTab(),
        );
      },
    );
  }
}
