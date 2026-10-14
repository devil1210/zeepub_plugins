import 'zeepub_cached_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


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


class VolumeDetailView extends StatefulWidget {
  final ZeepubVolume volume;

  const VolumeDetailView({super.key, required this.volume});

  @override
  State<VolumeDetailView> createState() => _VolumeDetailViewState();
}

class _VolumeDetailViewState extends State<VolumeDetailView> {
  bool _isSpecsOpen = true;

  String _buildCoverUrl(String? raw, String baseUrl, String bookHash) {
    if (raw != null && raw.trim().isNotEmpty) {
      if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
      final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
      final cleanPath = raw.startsWith('/') ? raw : '/$raw';
      return '$cleanBase$cleanPath';
    }
    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$cleanBase/api/bot/cover/$bookHash';
  }

  void _showTemplatePicker(BuildContext context, ZeepubVolume vol, ZeepubEditorialState state, ZeepubEditorialCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description_outlined, color: Color(0xFF818CF8)),
            SizedBox(width: 8),
            Text('Seleccionar Plantilla Editorial'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: state.templates.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No hay plantillas registradas')),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.templates.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
                  itemBuilder: (ctx, index) {
                    final t = state.templates[index];
                    return ListTile(
                      leading: Icon(
                        t.isDefault ? Icons.star_rounded : Icons.article_outlined,
                        color: t.isDefault ? Colors.amber : const Color(0xFF818CF8),
                      ),
                      title: Row(
                        children: [
                          Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          if (t.isDefault)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('POR DEFECTO', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        t.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        cubit.openPublisher(vol);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.publish_rounded, size: 16),
            label: const Text('Abrir en Publicador'),
            onPressed: () {
              Navigator.of(ctx).pop();
              cubit.openPublisher(vol);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<ZeepubEditorialCubit, ZeepubEditorialState>(
      builder: (context, state) {
        final vol = state.activeVolumeDetail ?? widget.volume;
        final s = state.activeSeriesDetail;
        final cubit = context.read<ZeepubEditorialCubit>();
        final coverUrl = _buildCoverUrl(vol.coverUrl, state.baseUrl, vol.bookHash);

        final seriesName = (s != null && s.seriesEnglish.isNotEmpty)
            ? s.seriesEnglish
            : (vol.seriesName.isNotEmpty ? vol.seriesName : 'Catálogo');

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
                      onTap: () {
                        cubit.closeVolumeDetail();
                        cubit.closeSeriesDetail();
                      },
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
                    if (s != null) ...[
                      InkWell(
                        onTap: () => cubit.closeVolumeDetail(),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Text(
                            seriesName,
                            style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 14, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        'Volumen ${vol.volume != null ? (vol.volume! % 1 == 0 ? vol.volume!.toInt() : vol.volume) : "1"}',
                        style: tt.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Volver'),
                      onPressed: () => cubit.closeVolumeDetail(),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content 2 Columns
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20.0),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT COLUMN: Huge Cover + Actions + Stats
                        SizedBox(
                          width: 320,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Cover Frame
                              Container(
                                height: 440,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: const Color(0xFF020617),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ZeepubCachedImage(
                                  imageUrl: coverUrl,
                                  fit: BoxFit.cover,
                                  fallbackIconSize: 64,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Programar & Plantilla Row
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.schedule_rounded, size: 16),
                                      label: const Text('PROGRAMAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      onPressed: () => cubit.openPublisher(vol),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.description_outlined, size: 16),
                                      label: const Text('PLANTILLA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      onPressed: () => _showTemplatePicker(context, vol, state, cubit),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Descargar en Navegador / Copiar Enlace
                              FilledButton.icon(
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text('DESCARGAR EPUB', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () {
                                  final dlUrl = '${state.baseUrl}/api/bot/download_file/${vol.bookHash}';
                                  Clipboard.setData(ClipboardData(text: dlUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Enlace copiado al portapapeles: $dlUrl'),
                                      backgroundColor: Colors.blue,
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 10),

                              // Enviar a mi Telegram
                              FilledButton.tonalIcon(
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: const Text('Enviar a mi Telegram', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                          const SizedBox(width: 12),
                                          Text('Enviando "${vol.spanishTitle.isNotEmpty ? vol.spanishTitle : vol.title}" a tu Telegram...'),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  await cubit.sendToTelegram(vol.bookHash);
                                },
                              ),

                              const SizedBox(height: 10),

                              // Editor Rápido
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFFFCD34D)),
                                label: const Text('EDITOR RÁPIDO', style: TextStyle(color: Color(0xFFFCD34D), fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: const Color(0xFFFCD34D).withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () => cubit.openVolumeEdit(vol),
                              ),

                              const SizedBox(height: 16),

                              // Stats Box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Column(
                                  children: [
                                    _buildStatRow('Valoración', '★ 5.0'),
                                    const Divider(height: 16, color: Colors.white10),
                                    _buildStatRow('Descargas Totales', '${vol.downloads > 0 ? vol.downloads : 7}'),
                                    const Divider(height: 16, color: Colors.white10),
                                    _buildStatRow('Última Actualización', vol.updatedAt ?? 'Reciente'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 28),

                        // RIGHT COLUMN: Title, Synopsis, Ficha Técnica, Historial
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fansub pill
                              if (vol.publisher != null && vol.publisher!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    vol.publisher!,
                                    style: const TextStyle(color: Color(0xFFA5B4FC), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // Book Title
                              Text(
                                vol.spanishTitle.isNotEmpty ? vol.spanishTitle : vol.title,
                                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                              ),

                              if (vol.englishTitle.isNotEmpty && vol.englishTitle != vol.spanishTitle)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    vol.englishTitle,
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ),

                              const SizedBox(height: 12),

                              // Metadata Line
                              Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                children: [
                                  if (vol.author != null && vol.author!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF818CF8)),
                                        const SizedBox(width: 4),
                                        Text(vol.author!, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                                      ],
                                    ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.tag_rounded, size: 14, color: Color(0xFF38BDF8)),
                                      const SizedBox(width: 4),
                                      Text('Vol. ${vol.volume ?? "1"}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  if (vol.translator != null && vol.translator!.isNotEmpty)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.translate_rounded, size: 14, color: Color(0xFFF472B6)),
                                        const SizedBox(width: 4),
                                        Text(vol.translator!, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                                      ],
                                    ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF94A3B8)),
                                      const SizedBox(width: 4),
                                      Text('Actualizado: ${vol.updatedAt ?? "Reciente"}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Genres pills
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  'NOVELA LIGERA',
                                  'DRAMA',
                                  'ROMANCE',
                                  'SOBRENATURAL',
                                  'COMEDIA',
                                  'ACCIÓN',
                                  'FANTASÍA',
                                  'CIENCIA FICCIÓN',
                                ].map((g) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Text(
                                    g,
                                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                )).toList(),
                              ),

                              const SizedBox(height: 20),

                              // SINOPSIS Card
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.subject_rounded, size: 16, color: Color(0xFF818CF8)),
                                            SizedBox(width: 6),
                                            Text('SINOPSIS', style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w900)),
                                          ],
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.edit_outlined, size: 14),
                                          label: const Text('Editar', style: TextStyle(fontSize: 11)),
                                          onPressed: () => cubit.openVolumeEdit(vol),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      vol.description != null && vol.description!.isNotEmpty
                                          ? _cleanHtmlText(vol.description)
                                          : 'Sin sinopsis registrada para este volumen.',
                                      style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.55),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // FICHA TÉCNICA Card (Collapsible)
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () => setState(() => _isSpecsOpen = !_isSpecsOpen),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF38BDF8)),
                                                SizedBox(width: 6),
                                                Text('FICHA TÉCNICA', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w900)),
                                              ],
                                            ),
                                            Icon(
                                              _isSpecsOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                              color: Colors.white60,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_isSpecsOpen)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                                        child: Column(
                                          children: [
                                            const Divider(height: 1, color: Colors.white10),
                                            const SizedBox(height: 14),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Left Col
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      _buildSpecRow('SERIE', seriesName),
                                                      _buildSpecRow('VOLUMEN', '${vol.volume ?? "1"}'),
                                                      _buildSpecRow('TIPO DE LIBRO', s?.bookType ?? 'Novela Ligera'),
                                                      _buildSpecRow('ISBN', vol.isbn ?? '978-48-4866-386-5'),
                                                      _buildSpecRow('ASIN', vol.asin ?? 'B01BK5LI4C'),
                                                      _buildSpecRow('IDIOMA', vol.language.isNotEmpty ? vol.language : 'es'),
                                                      _buildSpecRow('TRADUCTOR', vol.translator ?? 'Lestat Lamperouge'),
                                                      _buildSpecRow('GRUPO TRADUCTOR', vol.publisher ?? 'Kikuslirus Project Team'),
                                                      _buildSpecRow('FECHA DE PUBLICACIÓN', vol.publishedDate ?? '08/04/2004'),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 24),
                                                // Right Col
                                                Expanded(
                                                  child: Column(
                                                    children: [
                                                      _buildSpecRow('FORMATO', vol.format),
                                                      _buildSpecRow('VERSIÓN EPUB', vol.epubVersion),
                                                      _buildSpecRow('PALABRAS', '${vol.wordCount ?? 60773}'),
                                                      _buildSpecRow('PÁGINAS', '${vol.pageCount ?? 202}'),
                                                      _buildSpecRow('MAQUETADOR', vol.layoutBy ?? '#Zack'),
                                                      _buildSpecRow('LECTURA APROX.', '${vol.readingTimeMin ?? 303} min / 5.0 horas'),
                                                      _buildSpecRow('TAMAÑO', vol.sizeMb.isNotEmpty ? vol.sizeMb : '8.16 MB'),
                                                      _buildSpecRow('MODO DE COLOR', vol.colorMode == 'color' ? 'Ilustraciones a Color' : 'Blanco y Negro'),
                                                      _buildSpecRow('CENSURA', vol.isUncensored ? 'Sin Censura (+18)' : 'Estándar'),
                                                      _buildSpecRow('UPLOADER', 'ZeePub'),
                                                      _buildSpecRow('FECHA DE ACTUALIZACIÓN', vol.updatedAt ?? 'Reciente'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // HISTORIAL DE PUBLICACIONES Card
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.podcasts_rounded, size: 20, color: Color(0xFF818CF8)),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('HISTORIAL DE PUBLICACIONES', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                          SizedBox(height: 2),
                                          Text(
                                            'Sin registros de emisión en Facebook / Telegram para este volumen.',
                                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.icon(
                                      icon: const Icon(Icons.send_rounded, size: 14),
                                      label: const Text('Publicar en Redes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F46E5),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                      onPressed: () => cubit.openPublisher(vol),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 11, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
