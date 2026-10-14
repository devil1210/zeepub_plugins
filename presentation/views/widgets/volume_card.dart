import 'package:flutter/material.dart';

import '/features/zeepub_editorial/data/models/zeepub_volume.dart';

class VolumeCard extends StatelessWidget {
  final ZeepubVolume volume;
  final String baseUrl;
  final VoidCallback onEdit;
  final VoidCallback onPublish;

  const VolumeCard({
    super.key,
    required this.volume,
    required this.baseUrl,
    required this.onEdit,
    required this.onPublish,
  });

  String _buildCoverUrl() {
    if (volume.coverUrl == null || volume.coverUrl!.isEmpty) return '';
    if (volume.coverUrl!.startsWith('http')) return volume.coverUrl!;
    final cleanBase = baseUrl.replaceAll(RegExp(r"/+$"), "");
    final cleanPath = volume.coverUrl!.startsWith('/') ? volume.coverUrl! : '/${volume.coverUrl!}';
    return '$cleanBase$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final coverUrl = _buildCoverUrl();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: volume.hasBadMetadata
              ? cs.error.withValues(alpha: 0.6)
              : cs.outlineVariant.withValues(alpha: 0.4),
          width: volume.hasBadMetadata ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover art
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 76,
                  height: 110,
                  color: cs.surfaceContainerHighest,
                  child: coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.menu_book_rounded,
                            size: 36,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        )
                      : Icon(
                          Icons.menu_book_rounded,
                          size: 36,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Info & Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (volume.volume != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Vol. ${volume.volume! % 1 == 0 ? volume.volume!.toInt() : volume.volume}',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (volume.colorMode == 'color' || (volume.filename ?? '').toLowerCase().contains('[color]'))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade900.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.amber.shade700, width: 0.8),
                            ),
                            child: Text(
                              'COLOR',
                              style: tt.labelSmall?.copyWith(
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        if (volume.isUncensored)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade900.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade600, width: 0.8),
                            ),
                            child: Text(
                              'SIN CENSURA',
                              style: tt.labelSmall?.copyWith(
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        if (volume.hasBadMetadata)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 12, color: cs.onErrorContainer),
                                const SizedBox(width: 3),
                                Text(
                                  'Incompleto',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Spanish title or main title
                    Text(
                      volume.spanishTitle.isNotEmpty ? volume.spanishTitle : volume.title,
                      style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (volume.spanishTitle.isNotEmpty && volume.title != volume.spanishTitle)
                      Text(
                        volume.title,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 4),

                    // Fansub / Publisher & Translator
                    Row(
                      children: [
                        Icon(Icons.business_outlined, size: 13, color: cs.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            volume.publisher != null && volume.publisher!.isNotEmpty
                                ? volume.publisher!
                                : 'Sin fansub asignado',
                            style: tt.labelSmall?.copyWith(
                              color: volume.publisher != null && volume.publisher!.isNotEmpty
                                  ? cs.primary
                                  : cs.error,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    if (volume.translator != null && volume.translator!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.translate_rounded, size: 13, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Trad: ${volume.translator}',
                                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Action buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Editar metadatos',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    tooltip: 'Publicar en Telegram',
                    color: cs.primary,
                    onPressed: onPublish,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
