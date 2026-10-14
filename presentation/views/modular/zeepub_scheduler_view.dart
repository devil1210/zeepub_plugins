import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/zeepub_editorial_cubit.dart';
import '../../cubit/zeepub_editorial_state.dart';
import '../widgets/calendar_tab.dart';
import '../widgets/posts_tab.dart';
import '../widgets/templates_tab.dart';
import '../widgets/zeepub_server_config_dialog.dart';
import '../zeepub_publisher_view.dart';

/// Vista modular del Programador de Publicaciones de ZeePub.
///
/// Gestiona la agenda de publicaciones, el historial y cola hacia Telegram,
/// y las plantillas de formato para los mensajes.
class ZeepubSchedulerView extends StatefulWidget {
  const ZeepubSchedulerView({super.key});

  @override
  State<ZeepubSchedulerView> createState() => _ZeepubSchedulerViewState();
}

class _ZeepubSchedulerViewState extends State<ZeepubSchedulerView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ZeepubEditorialCubit>();
      if (cubit.state.queue.isEmpty && cubit.state.posts.isEmpty) {
        cubit.init();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

        // Overlay: Publisher
        if (state.publishingVolume != null) {
          return ZeepubPublisherView(
            volume: state.publishingVolume!,
            baseUrl: state.baseUrl,
            onBack: () => cubit.closePublisher(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Color(0xFF818CF8)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Programador de Publicaciones', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(
                      'Agenda, cola hacia Telegram y plantillas dinámicas',
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
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF6366F1),
              labelColor: const Color(0xFF818CF8),
              unselectedLabelColor: cs.onSurfaceVariant,
              tabs: [
                Tab(
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  text: 'Agenda (${state.queue.length})',
                ),
                Tab(
                  icon: const Icon(Icons.history_outlined, size: 16),
                  text: 'Historial y Cola (${state.posts.length})',
                ),
                Tab(
                  icon: const Icon(Icons.description_outlined, size: 16),
                  text: 'Plantillas (${state.templates.length})',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              ZeepubCalendarTab(),
              ZeepubPostsTab(),
              ZeepubTemplatesTab(),
            ],
          ),
        );
      },
    );
  }
}
