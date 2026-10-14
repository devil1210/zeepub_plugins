import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';
import 'widgets/calendar_tab.dart';
import 'widgets/posts_tab.dart';
import 'widgets/series_card.dart';
import 'widgets/series_detail_view.dart';
import 'widgets/templates_tab.dart';
import 'widgets/volume_detail_view.dart';
import 'widgets/workgroup_detail_view.dart';
import 'widgets/workgroups_tab.dart';
import 'zeepub_publisher_view.dart';
import 'zeepub_volume_edit_view.dart';

class ZeepubEditorialView extends StatefulWidget {
  const ZeepubEditorialView({super.key});

  @override
  State<ZeepubEditorialView> createState() => _ZeepubEditorialViewState();
}

class _ZeepubEditorialViewState extends State<ZeepubEditorialView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _seriesSearchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _sortOptions = [
    {'id': 'name_asc', 'label': 'Título (A - Z)'},
    {'id': 'name_desc', 'label': 'Título (Z - A)'},
    {'id': 'updated_desc', 'label': 'Más Recientes'},
    {'id': 'books_desc', 'label': 'Más Volúmenes'},
    {'id': 'downloads_desc', 'label': 'Más Descargados'},
    {'id': 'rating_desc', 'label': 'Mejor Valorados'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZeepubEditorialCubit>().init();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _seriesSearchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 500) {
      context.read<ZeepubEditorialCubit>().loadMoreSeries();
    }
  }

  void _showConfigServerDialog(BuildContext context, String currentUrl, String currentTgId, double currentScale) {
    final urlController = TextEditingController(text: currentUrl);
    final tgIdController = TextEditingController(text: currentTgId);
    final cubit = context.read<ZeepubEditorialCubit>();
    double selectedScale = currentScale;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.tune_rounded),
            SizedBox(width: 8),
            Text('Ajustes del Servidor ZeePub'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL del Servidor (VPS / Local)',
                  hintText: 'http://176.223.137.101:8001',
                  helperText: 'Dirección IP o dominio del backend de ZeePub con su puerto.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tgIdController,
                decoration: const InputDecoration(
                  labelText: 'ID de Telegram (Admin / Staff)',
                  hintText: '133994080',
                  helperText: 'Tu ID numérico de Telegram para identificarte como Admin/Staff provisoriamente.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),
              StatefulBuilder(
                builder: (context, setLocalState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.photo_size_select_actual_outlined, size: 16, color: Color(0xFF818CF8)),
                              SizedBox(width: 8),
                              Text(
                                'Escala de Portadas',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(selectedScale * 100).toInt()}%',
                              style: const TextStyle(
                                color: Color(0xFF38BDF8),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF38BDF8),
                          inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                          thumbColor: const Color(0xFF38BDF8),
                          overlayColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: selectedScale,
                          min: 0.70,
                          max: 1.50,
                          divisions: 16,
                          onChanged: (val) {
                            setLocalState(() => selectedScale = val);
                            cubit.setCoverScale(val);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Guardar y Conectar'),
            onPressed: () {
              final newUrl = urlController.text.trim();
              final newTgId = tgIdController.text.trim();
              Navigator.of(ctx).pop();
              cubit.saveServerConfig(url: newUrl, tgId: newTgId);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuración guardada. Conectando con el servidor...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
        ],
      ),
    );
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

        // 1. Modal/Overlay: Publisher Screen
        if (state.publishingVolume != null) {
          return ZeepubPublisherView(
            volume: state.publishingVolume!,
            baseUrl: state.baseUrl,
            onBack: () => cubit.closePublisher(),
          );
        }

        // 2. Modal/Overlay: Volume Editor Screen
        if (state.activeVolume != null) {
          return ZeepubVolumeEditView(
            volume: state.activeVolume!,
            volumes: state.volumes,
            seriesList: state.seriesList,
            workgroups: state.workgroups,
            baseUrl: state.baseUrl,
            onBack: () => cubit.closeVolumeEdit(),
          );
        }

        // 3. Navigation: Full Volume Detail Screen (Nivel 3)
        if (state.activeVolumeDetail != null) {
          return VolumeDetailView(volume: state.activeVolumeDetail!);
        }

        // 4. Navigation: Full Series Detail Screen (Nivel 2)
        if (state.activeSeriesDetail != null) {
          return SeriesDetailView(series: state.activeSeriesDetail!);
        }

        // 5. Navigation: Workgroup Detail & Auditoria Screen (Nivel 2)
        if (state.activeWorkgroupDetail != null) {
          return WorkgroupDetailView(detail: state.activeWorkgroupDetail!, initialTab: state.workgroupDetailInitialTab);
        }

        // 6. Root Editorial Screen
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.layers_rounded, color: Color(0xFF818CF8)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Catálogo Editorial ZeePub', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(
                      'Exploración completa de la biblioteca con navegación tipo árbol (${state.seriesTotalCount} series indexadas)',
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
                onPressed: () => _showConfigServerDialog(
                  context,
                  state.baseUrl,
                  state.telegramUserId,
                  state.coverScale,
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
                  icon: const Icon(Icons.layers_outlined, size: 16),
                  text: 'Catálogo (${state.seriesTotalCount})',
                ),
                Tab(
                  icon: const Icon(Icons.groups_outlined, size: 16),
                  text: 'Fansubs (${state.workgroups.length})',
                ),
                Tab(
                  icon: const Icon(Icons.description_outlined, size: 16),
                  text: 'Plantillas (${state.templates.length})',
                ),
                Tab(
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  text: 'Agenda (${state.queue.length})',
                ),
                Tab(
                  icon: const Icon(Icons.history_outlined, size: 16),
                  text: 'Historial (${state.posts.length})',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSeriesCatalogTab(context, state, cubit),
              const ZeepubWorkgroupsTab(),
              const ZeepubTemplatesTab(),
              const ZeepubCalendarTab(),
              const ZeepubPostsTab(),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: CATÁLOGO DE SERIES (Exploración / Árbol)
  // ==========================================
  Widget _buildSeriesCatalogTab(BuildContext context, ZeepubEditorialState state, ZeepubEditorialCubit cubit) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Top Filter & Search Controls
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.6),
            border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _seriesSearchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar serie por título en español, inglés o romaji...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _seriesSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _seriesSearchController.clear();
                                  cubit.loadSeriesCatalog(reset: true, query: '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (val) => cubit.loadSeriesCatalog(reset: true, query: val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      initialValue: state.seriesSortBy,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ordenar por',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                      items: [
                        for (final opt in _sortOptions)
                          DropdownMenuItem(value: opt['id'], child: Text(opt['label']!, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) cubit.loadSeriesCatalog(reset: true, sortBy: val);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Recargar catálogo',
                    onPressed: () => cubit.loadSeriesCatalog(reset: true),
                  ),
                ],
              ),

            ],
          ),
        ),

        // Series Vertical Grid
        Expanded(
          child: state.loadingSeries
              ? const Center(child: CircularProgressIndicator())
              : state.seriesCatalog.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.layers_clear_outlined, size: 64, color: cs.outlineVariant),
                          const SizedBox(height: 16),
                          const Text('No se encontraron series en el catálogo.'),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar conexión'),
                            onPressed: () => cubit.init(),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 185 * state.coverScale,
                              childAspectRatio: (185.0 * state.coverScale) /
                                  ((185.0 * state.coverScale - 18.0) * 1.45 + 105.0),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: state.seriesCatalog.length,
                            itemBuilder: (context, index) {
                              final series = state.seriesCatalog[index];
                              return SeriesCard(
                                series: series,
                                baseUrl: state.baseUrl,
                                onTap: () => cubit.openSeriesDetail(series),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          if (state.loadingMoreSeries)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (state.seriesCurrentPage < state.seriesTotalPages)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.expand_more_rounded),
                                  label: Text(
                                    'Cargar más series (${state.seriesCatalog.length} de ${state.seriesTotalCount})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                    side: BorderSide(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => cubit.loadMoreSeries(),
                                ),
                              ),
                            )
                          else if (state.seriesCatalog.isNotEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  '✨ Has llegado al final del catálogo (${state.seriesCatalog.length} series)',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}
