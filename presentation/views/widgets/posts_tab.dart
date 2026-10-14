import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';
import 'zeepub_cached_image.dart';

class ZeepubPostsTab extends StatefulWidget {
  const ZeepubPostsTab({super.key});

  @override
  State<ZeepubPostsTab> createState() => _ZeepubPostsTabState();
}

class _ZeepubPostsTabState extends State<ZeepubPostsTab> {
  String _selectedTab = 'all'; // 'all', 'telegram', 'facebook'
  final Map<String, bool> _expandedMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ZeepubEditorialCubit>().loadPosts();
    });
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return 'Reciente';
    try {
      final normalized = dateStr.endsWith('Z') || dateStr.contains('+') ? dateStr : '${dateStr}Z';
      final d = DateTime.parse(normalized).toLocal();
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      final year = d.year.toString();
      final hour24 = d.hour;
      final minute = d.minute.toString().padLeft(2, '0');
      final second = d.second.toString().padLeft(2, '0');
      final period = hour24 >= 12 ? 'p. m.' : 'a. m.';
      final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
      final hour12Str = hour12.toString().padLeft(2, '0');
      return '$day/$month/$year, $hour12Str:$minute:$second $period';
    } catch (_) {
      return dateStr;
    }
  }

  String _getTimezoneLabel() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours;
    final sign = hours >= 0 ? '+' : '-';
    final absHours = hours.abs().toString().padLeft(2, '0');
    return 'Hora Local (${now.timeZoneName.isNotEmpty ? now.timeZoneName : "UTC$sign$absHours"})';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ZeepubEditorialCubit, ZeepubEditorialState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final cubit = context.read<ZeepubEditorialCubit>();
        final allPosts = state.posts;

        final filtered = allPosts.where((p) {
          if (_selectedTab == 'all') return true;
          return p.platform.toLowerCase() == _selectedTab;
        }).toList();

        final tgCount = allPosts.where((p) => p.platform.toLowerCase() == 'telegram').length;
        final fbCount = allPosts.where((p) => p.platform.toLowerCase() == 'facebook').length;

        return Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.history_rounded, color: Color(0xFF818CF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Historial de Publicaciones Enviadas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Registro consolidado de todas las entregas realizadas en Telegram y redes sociales.',
                          style: TextStyle(fontSize: 11, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Timezone Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF818CF8)),
                        const SizedBox(width: 6),
                        Text(_getTimezoneLabel(), style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Filter Tabs
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        _filterTab('Todos', 'all', allPosts.length),
                        _filterTab('Telegram', 'telegram', tgCount),
                        _filterTab('Facebook', 'facebook', fbCount),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Actualizar historial',
                    onPressed: () => cubit.loadPosts(),
                  ),
                ],
              ),
            ),

            // Posts List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.feed_outlined, size: 54, color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay publicaciones registradas en el historial.',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final post = filtered[idx];
                        final isFb = post.platform.toLowerCase() == 'facebook';
                        final isExpanded = _expandedMap[post.id] ?? false;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Cover
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 44,
                                      height: 62,
                                      child: ZeepubCachedImage(
                                        imageUrl: post.coverUrl ?? '',
                                        baseUrl: state.baseUrl,
                                        fit: BoxFit.cover,
                                        placeholder: Container(
                                          color: Colors.black26,
                                          child: const Center(child: Icon(Icons.menu_book, size: 20, color: Colors.white24)),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                post.bookTitle,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (post.volume != null) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Vol. ${post.volume! % 1 == 0 ? post.volume!.toInt() : post.volume}',
                                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isFb
                                                    ? Colors.blue.withValues(alpha: 0.2)
                                                    : Colors.cyan.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isFb ? Icons.facebook_rounded : Icons.send_rounded,
                                                    size: 10,
                                                    color: isFb ? Colors.blueAccent : Colors.cyanAccent,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    post.platform.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      color: isFb ? Colors.blueAccent : Colors.cyanAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              post.channelName,
                                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF818CF8)),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDateTime(post.publishedAt),
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF818CF8), fontFamily: 'monospace'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Trailing items (ID chip & expand button)
                                  if (post.id.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                      ),
                                      child: Text(
                                        'ID: ${post.id}',
                                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white60),
                                      ),
                                    ),

                                  if (post.caption != null && post.caption!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20),
                                      onPressed: () {
                                        setState(() => _expandedMap[post.id] = !isExpanded);
                                      },
                                    ),
                                  ],
                                ],
                              ),

                              // Expandable Caption
                              if (isExpanded && post.caption != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    post.caption!,
                                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70, height: 1.4),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterTab(String label, String mode, int count) {
    final isSelected = _selectedTab == mode;
    return InkWell(
      onTap: () => setState(() => _selectedTab = mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($count)',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: isSelected ? Colors.white : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
