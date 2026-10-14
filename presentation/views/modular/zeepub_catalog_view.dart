import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/zeepub_editorial_cubit.dart';
import '../../cubit/zeepub_editorial_state.dart';
import '../widgets/series_card.dart';
import '../widgets/series_detail_view.dart';
import '../widgets/volume_detail_view.dart';
import '../widgets/zeepub_server_config_dialog.dart';
import '../zeepub_publisher_view.dart';
import '../zeepub_volume_edit_view.dart';

/// Vista modular del Catálogo ZeePub.
///
/// Permite explorar la biblioteca de novelas y mangas, buscar títulos,
/// ordenar resultados e interactuar con los volúmenes de cada serie.
class ZeepubCatalogView extends StatefulWidget {
  const ZeepubCatalogView({super.key});

  @override
  State<ZeepubCatalogView> createState() => _ZeepubCatalogViewState();
}

class _ZeepubCatalogViewState extends State<ZeepubCatalogView> {
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
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ZeepubEditorialCubit>();
      if (cubit.state.seriesCatalog.isEmpty) {
        cubit.init();
      }
    });
  }

  @override
  void dispose() {
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

        // 1. Overlay: Publisher
        if (state.publishingVolume != null) {
          return ZeepubPublisherView(
            volume: state.publishingVolume!,
            baseUrl: state.baseUrl,
            onBack: () => cubit.closePublisher(),
          );
        }

        // 2. Overlay: Volume Editor
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

        // 3. Navigation: Volume Detail (Nivel 3)
        if (state.activeVolumeDetail != null) {
          return VolumeDetailView(volume: state.activeVolumeDetail!);
        }

        // 4. Navigation: Series Detail (Nivel 2)
        if (state.activeSeriesDetail != null) {
          return SeriesDetailView(series: state.activeSeriesDetail!);
        }

        // 5. Main Catalog Root
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.auto_stories_rounded, color: Color(0xFF818CF8)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Catálogo ZeePub', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(
                      'Biblioteca digital (${state.seriesTotalCount} series indexadas)',
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
          body: Column(
            children: [
              // Search & Filter header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.6),
                  border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2))),
                ),
                child: Row(
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
              ),

              // Grid of Series
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
                                        '✓ Has llegado al final del catálogo (${state.seriesCatalog.length} series)',
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
          ),
        );
      },
    );
  }
}
