import 'package:flutter/material.dart';

import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import 'zeepub_cached_image.dart';

class SeriesCard extends StatelessWidget {
  final ZeepubSeries series;
  final String baseUrl;
  final VoidCallback onTap;

  const SeriesCard({
    super.key,
    required this.series,
    required this.baseUrl,
    required this.onTap,
  });

  String _buildCoverUrl() {
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (series.coverUrl.isEmpty) {
      if (series.books.isNotEmpty && series.books.first.coverUrl != null && series.books.first.coverUrl!.isNotEmpty) {
        final bCover = series.books.first.coverUrl!;
        if (bCover.startsWith('http://') || bCover.startsWith('https://')) return bCover;
        final cleanPath = bCover.startsWith('/') ? bCover : '/$bCover';
        return '$cleanBase$cleanPath';
      }
      final hash = series.seriesHash.isNotEmpty ? series.seriesHash : series.id;
      return '$cleanBase/api/bot/cover/$hash';
    }
    if (series.coverUrl.startsWith('http://') || series.coverUrl.startsWith('https://')) {
      return series.coverUrl;
    }
    final cleanPath = series.coverUrl.startsWith('/') ? series.coverUrl : '/${series.coverUrl}';
    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fullCoverUrl = _buildCoverUrl();

    final mainTitle = series.seriesEnglish.isNotEmpty
        ? series.seriesEnglish
        : (series.name.isNotEmpty ? series.name : 'Sin título');

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      color: cs.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
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
                        borderRadius: BorderRadius.circular(10),
                        color: cs.surfaceContainerHighest,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ZeepubCachedImage(
                        imageUrl: fullCoverUrl,
                        fit: BoxFit.cover,
                        fallbackIconSize: 36,
                      ),
                    ),

                    // Book Count Badge (Top Right)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 3.5),
                            Text(
                              '${series.bookCount} Vol.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Incomplete Badge (Top Left)
                    if (series.hasBadMetadata)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'Incompleto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 2. Info area wrapped in Expanded (Guarantees zero overflow)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Main Title (Crisp & Readable 2-lines)
                        Text(
                          mainTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            height: 1.2,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        if (series.seriesSpanish.isNotEmpty && series.seriesSpanish != mainTitle) ...[
                          const SizedBox(height: 2),
                          Text(
                            series.seriesSpanish,
                            style: const TextStyle(
                              color: Color(0xFFFCD34D),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 2),

                        // Author (1-line)
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 11, color: cs.primary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                series.author.isNotEmpty ? series.author : 'Sin autor',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                                  fontSize: 10.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Footer: Demography Tag & Link
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25), width: 0.5),
                              ),
                              child: Text(
                                series.demographics.isNotEmpty
                                    ? series.demographics.first.toUpperCase()
                                    : series.bookType.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explorar',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 13, color: cs.primary),
                          ],
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
}
