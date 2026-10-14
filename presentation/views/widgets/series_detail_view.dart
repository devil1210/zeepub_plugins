import 'zeepub_cached_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';

String _cleanHtmlText(String? raw) {
  if (raw == null) return '';
  return raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}


class SeriesDetailView extends StatefulWidget {
  final ZeepubSeries series;

  const SeriesDetailView({super.key, required this.series});

  @override
  State<SeriesDetailView> createState() => _SeriesDetailViewState();
}

class _SeriesDetailViewState extends State<SeriesDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSynopsisExpanded = false;
  String _volumeViewMode = 'grid';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _buildCoverUrl(String? raw, String baseUrl) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = raw.startsWith('/') ? raw : '/$raw';
    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<ZeepubEditorialCubit, ZeepubEditorialState>(
      builder: (context, state) {
        final s = state.activeSeriesDetail ?? widget.series;
        final books = List<ZeepubVolume>.from(
          state.activeSeriesBooks.isNotEmpty ? state.activeSeriesBooks : s.books,
        )..sort((a, b) {
          final vA = a.volume ?? 999999.0;
          final vB = b.volume ?? 999999.0;
          if (vA != vB) return vA.compareTo(vB);
          return (a.filename ?? a.title).compareTo(b.filename ?? b.title);
        });
        final cubit = context.read<ZeepubEditorialCubit>();
        final coverUrl = _buildCoverUrl(s.coverUrl, state.baseUrl);

        return Scaffold(
          body: Column(
            children: [
              // Top Breadcrumbs & Back bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.8),
                  border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15))),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => cubit.closeSeriesDetail(),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.layers_rounded, size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                            Text('Catálogo Editorial', style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        s.seriesEnglish.isNotEmpty ? s.seriesEnglish : s.name,
                        style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Volver al Catálogo'),
                      onPressed: () => cubit.closeSeriesDetail(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Scrollable
              Expanded(
                child: state.loadingSeriesDetail && books.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.all(20.0),
                        children: [
                          // Series Hero Banner
                          _buildHeroBanner(context, s, coverUrl, books.length),

                          const SizedBox(height: 20),

                          // Tabs & Action Controls
                          _buildActionBar(context, s, books.length, cubit, state.coverScale),

                          const SizedBox(height: 16),

                          // Volumes Grid / List
                          if (books.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(36),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.15)),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.menu_book_outlined, size: 48, color: cs.outlineVariant),
                                    const SizedBox(height: 12),
                                    const Text('No hay volúmenes vinculados a esta serie.'),
                                  ],
                                ),
                              ),
                            )
                          else if (_volumeViewMode == 'grid') ...[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 185 * state.coverScale,
                                childAspectRatio: (185.0 * state.coverScale) /
                                    ((185.0 * state.coverScale - 18.0) * 1.40 + 115.0),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                final vol = books[index];
                                return _buildVolumeGridCard(context, vol, s, state.baseUrl, cubit);
                              },
                            ),
                          ]
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: books.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final vol = books[index];
                                return _buildVolumeListTile(context, vol, s, state.baseUrl, cubit);
                              },
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, ZeepubSeries s, String coverUrl, int totalBooks) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Cover
          Container(
            width: 140,
            height: 205,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cs.surfaceContainerHighest,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ZeepubCachedImage(
              imageUrl: coverUrl,
              fit: BoxFit.cover,
              fallbackIconSize: 44,
            ),
          ),

          const SizedBox(width: 24),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        s.bookType.toUpperCase(),
                        style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (s.demographics.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          s.demographics.first.toUpperCase(),
                          style: const TextStyle(color: Color(0xFFD8B4FE), fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                    if (s.slug.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Text(
                          '#${s.slug}',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Main Title
                Text(
                  s.seriesEnglish.isNotEmpty ? s.seriesEnglish : s.name,
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                ),

                if (s.seriesSpanish.isNotEmpty && s.seriesSpanish != s.seriesEnglish)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      s.seriesSpanish,
                      style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),

                const SizedBox(height: 8),

                // Metadata Line
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (s.author.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF818CF8)),
                          const SizedBox(width: 4),
                          Text(s.author, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                        ],
                      ),
                    if (s.illustrator.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.brush_outlined, size: 14, color: Color(0xFFF472B6)),
                          const SizedBox(width: 4),
                          Text(s.illustrator, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                        ],
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories_rounded, size: 14, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 4),
                        Text('$totalBooks Volúmenes', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Synopsis
                if (s.description != null && s.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _cleanHtmlText(s.description),
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.45),
                        maxLines: _isSynopsisExpanded ? null : 3,
                        overflow: _isSynopsisExpanded ? null : TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => setState(() => _isSynopsisExpanded = !_isSynopsisExpanded),
                        child: Text(
                          _isSynopsisExpanded ? 'Ocultar sinopsis ⌃' : 'Leer sinopsis completa ⌄',
                          style: const TextStyle(color: Color(0xFF818CF8), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, ZeepubSeries s, int totalBooks, ZeepubEditorialCubit cubit, double coverScale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), blurRadius: 6),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.book_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Volúmenes ($totalBooks)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.grid_view_rounded, size: 20, color: _volumeViewMode == 'grid' ? const Color(0xFF818CF8) : Colors.white54),
              onPressed: () => setState(() => _volumeViewMode = 'grid'),
              tooltip: 'Vista Cuadrícula',
            ),
            IconButton(
              icon: Icon(Icons.view_list_rounded, size: 22, color: _volumeViewMode == 'list' ? const Color(0xFF818CF8) : Colors.white54),
              onPressed: () => setState(() => _volumeViewMode = 'list'),
              tooltip: 'Vista Lista',
            ),
          ],
        ),
      ],
    );
  }

    Widget _buildVolumeGridCard(BuildContext context, ZeepubVolume vol, ZeepubSeries s, String baseUrl, ZeepubEditorialCubit cubit) {
    final cs = Theme.of(context).colorScheme;
    final coverUrl = _buildCoverUrl(vol.coverUrl ?? s.coverUrl, baseUrl);

    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      color: cs.surfaceContainerLow,
      child: InkWell(
        onTap: () => cubit.openVolumeDetail(vol, s),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Fixed Aspect Ratio Cover (Uniform 1:1.40 book ratio)
              AspectRatio(
                aspectRatio: 1 / 1.40,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ZeepubCachedImage(
                        imageUrl: coverUrl.isNotEmpty ? coverUrl : '${baseUrl.replaceAll(RegExp(r"/+$"), "")}/api/bot/cover/${vol.bookHash}',
                        fit: BoxFit.cover,
                        fallbackIconSize: 36,
                      ),
                    ),

                    // Volume badge
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                        ),
                        child: Text(
                          'Vol. ${vol.volume != null ? (vol.volume! % 1 == 0 ? vol.volume!.toInt() : vol.volume) : "?"}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Size badge
                    if (vol.sizeMb.isNotEmpty)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            vol.sizeMb,
                            style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 2. Info area in Expanded
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          vol.spanishTitle.isNotEmpty ? vol.spanishTitle : vol.title,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.translate_rounded, size: 11, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                vol.translator != null && vol.translator!.isNotEmpty ? vol.translator! : (vol.publisher ?? 'Sin fansub'),
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF94A3B8)),
                          tooltip: 'Editar',
                          onPressed: () => cubit.openVolumeEdit(vol),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, size: 14, color: Color(0xFF818CF8)),
                          tooltip: 'Publicar',
                          onPressed: () => cubit.openPublisher(vol),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeListTile(BuildContext context, ZeepubVolume vol, ZeepubSeries s, String baseUrl, ZeepubEditorialCubit cubit) {
    final cs = Theme.of(context).colorScheme;
    final coverUrl = _buildCoverUrl(vol.coverUrl, baseUrl);

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        onTap: () => cubit.openVolumeDetail(vol, s),
        leading: Container(
          width: 40,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: cs.surfaceContainerHighest,
          ),
          clipBehavior: Clip.antiAlias,
          child: coverUrl.isNotEmpty
              ? Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.book, size: 20))
              : const Icon(Icons.book, size: 20),
        ),
        title: Text(
          vol.spanishTitle.isNotEmpty ? vol.spanishTitle : vol.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          'Vol. ${vol.volume ?? "?"}  •  ${vol.translator ?? vol.publisher ?? "Sin traductor"}  •  ${vol.sizeMb}',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.publish_rounded, size: 18, color: Color(0xFF38BDF8)),
              onPressed: () => cubit.openPublisher(vol),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFFFCD34D)),
              onPressed: () => cubit.openVolumeEdit(vol),
            ),
          ],
        ),
      ),
    );
  }
}
