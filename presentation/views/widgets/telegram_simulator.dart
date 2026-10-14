import '/inject_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/features/zeepub_editorial/data/models/zeepub_channel.dart';
import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/data/repositories/zeepub_editorial_repository.dart';
import 'zeepub_cached_image.dart';

class TelegramSimulator extends StatefulWidget {
  final String templateContent;
  final ZeepubVolume? volume;
  final ZeepubSeries? series;
  final ZeepubChannel? channel;
  final String? customCoverUrl;
  final bool sendAsFile;

  const TelegramSimulator({
    super.key,
    required this.templateContent,
    this.volume,
    this.series,
    this.channel,
    this.customCoverUrl,
    this.sendAsFile = true,
  });

  @override
  State<TelegramSimulator> createState() => _TelegramSimulatorState();
}

class _TelegramSimulatorState extends State<TelegramSimulator> {
  bool _showFicha = true;
  bool _showSinopsis = false;
  String _viewMode = 'desktop'; // 'desktop' | 'mobile'
  bool _copied = false;

  // Selected Volume for preview (real library book)
  ZeepubVolume? _selectedVolume;
  late final ZeepubEditorialRepository _repo = getIt<ZeepubEditorialRepository>();

  @override
  void initState() {
    super.initState();
    _selectedVolume = widget.volume;
  }

  @override
  void didUpdateWidget(covariant TelegramSimulator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.volume != null && widget.volume != oldWidget.volume) {
      _selectedVolume = widget.volume;
    }
  }

  void _showVolumeSearchDialog(BuildContext context) {
    final searchCtrl = TextEditingController();
    List<ZeepubVolume> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          Future<void> doSearch(String q) async {
            if (q.trim().length < 2) return;
            setDlgState(() => isSearching = true);
            try {
              final res = await _repo.getVolumes(query: q.trim(), pageSize: 20);
              setDlgState(() {
                searchResults = res.items;
                isSearching = false;
              });
            } catch (_) {
              setDlgState(() => isSearching = false);
            }
          }

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.menu_book_rounded, color: Color(0xFF818CF8)),
                SizedBox(width: 8),
                Text('Seleccionar Tomo de Ejemplo', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: SizedBox(
              width: 520,
              height: 420,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Buscar por título de serie, tomo o autor...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: () => doSearch(searchCtrl.text),
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (val) => doSearch(val),
                  ),
                  const SizedBox(height: 12),
                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )
                  else if (searchResults.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          searchCtrl.text.isEmpty
                              ? 'Escribe el nombre de una serie o tomo para buscar en tu biblioteca.'
                              : 'No se encontraron tomos coincidentes.',
                          style: const TextStyle(fontSize: 12, color: Colors.white60),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (c, idx) {
                          final vol = searchResults[idx];
                          return ListTile(
                            dense: true,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                width: 32,
                                height: 44,
                                child: ZeepubCachedImage(
                                  imageUrl: vol.coverUrl ?? '',
                                  baseUrl: _repo.baseUrl,
                                  fit: BoxFit.cover,
                                  placeholder: const Center(child: Icon(Icons.book, size: 16, color: Colors.white30)),
                                ),
                              ),
                            ),
                            title: Text(
                              vol.displayTitle,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Vol. ${vol.volume != null ? (vol.volume! % 1 == 0 ? vol.volume!.toInt() : vol.volume) : 1} · ${vol.author ?? "Autor desconocido"}',
                              style: const TextStyle(fontSize: 10, color: Colors.white60),
                            ),
                            onTap: () {
                              setState(() => _selectedVolume = vol);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
            ],
          );
        },
      ),
    );
  }

  String _formatGenres(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '#NovelaLigera #Romance #Comedia';
    final parts = raw.split(RegExp(r'[,;|]')).map((s) => s.trim()).where((s) => s.isNotEmpty);
    return parts.map((g) {
      final clean = g.replaceAll('#', '').trim().replaceAll(' ', '_');
      return '#$clean';
    }).join(' ');
  }

  String _interpolate(String tpl) {
    final v = _selectedVolume ?? widget.volume;
    final s = widget.series;

    final serieEng = (v?.englishTitle.isNotEmpty == true)
        ? v!.englishTitle
        : ((s != null && s.seriesEnglish.isNotEmpty) ? s.seriesEnglish : (s?.name ?? 'Alya Sometimes Hides Her Feelings in Russian'));
    final serieSpa = (v?.spanishTitle.isNotEmpty == true)
        ? v!.spanishTitle
        : ((s != null && s.seriesSpanish.isNotEmpty) ? s.seriesSpanish : 'Alya-san, quien se sienta a mi lado, a veces susurra cosas dulces en ruso');
    final serieRom = (s != null && s.name.isNotEmpty) ? s.name : 'Tokidoki Bosotto Russiago de Dereru Tonari no Arya-san';
    final volNum = v?.volume != null ? (v!.volume! % 1 == 0 ? v.volume!.toInt().toString() : v.volume!.toString()) : '3.0';
    final autor = (v?.author != null && v!.author!.isNotEmpty) ? v.author! : ((s != null && s.author.isNotEmpty) ? s.author : 'SunsunSUN');
    final ilustrador = (v?.illustrator != null && v!.illustrator!.isNotEmpty) ? v.illustrator! : ((s != null && s.illustrator.isNotEmpty) ? s.illustrator : 'Momoco');
    final traductor = (v?.translator != null && v!.translator!.isNotEmpty) ? v.translator! : 'Vlady Pasos';
    final layoutBy = (v?.layoutBy != null && v!.layoutBy!.isNotEmpty) ? v.layoutBy! : 'Yayo';
    final editorial = (v?.publisher != null && v!.publisher!.isNotEmpty) ? v.publisher! : ((s != null && s.publisher.isNotEmpty) ? s.publisher : 'Darkness Dragons Translation');
    final sinopsis = (v?.description != null && v!.description!.isNotEmpty)
        ? v.description!
        : ((s?.description != null && s!.description!.isNotEmpty)
            ? s.description!
            : 'Alisa Mikhailovna Kujou es la "princesa solitaria" de la academia Seirei. Es una belleza mitad rusa y mitad japonesa con cabello plateado...');
    final demography = v?.colorMode == 'color' ? 'Shoujo' : 'Novela Ligera';
    final genres = _formatGenres('#Comedia #Romance #Escolar');
    final slug = (s != null && s.slug.isNotEmpty) ? s.slug : 'Tokidoki_Bosotto_Russiago_De_Dereru_Tonari_No_Aryasan';
    final fecha = DateTime.now().toString().split(' ')[0];

    final values = <String, String>{
      'serie': serieEng,
      'series': serieEng,
      'series_english': serieEng,
      'series_name': serieEng,
      'series_spanish': serieSpa,
      'romaji_title': serieRom,
      'titulo': serieSpa,
      'title': serieSpa,
      'volumen': volNum,
      'volume': volNum,
      'autor': autor,
      'author': autor,
      'illustrator': ilustrador,
      'ilustrador': ilustrador,
      'traductor': traductor,
      'translator': traductor,
      'layout_by': layoutBy,
      'maquetador': layoutBy,
      'editorial': editorial,
      'publisher': editorial,
      'sinopsis': sinopsis,
      'synopsis': sinopsis,
      'demography': demography,
      'genres': genres,
      'slug': slug,
      'fecha': fecha,
      'published_at': fecha,
      'download_link': 'https://dl.zeepubs.com/QfFLyhydJK',
    };

    var result = tpl;

    // Evaluate conditional blocks [?variable]...[/?]
    result = result.replaceAllMapped(RegExp(r'\[\?([a-zA-Z0-9_]+)\]([\s\S]*?)\[\/\?\]'), (m) {
      final tag = m.group(1)?.toLowerCase() ?? '';
      final inner = m.group(2) ?? '';
      final val = values[tag];
      if (val != null && val.isNotEmpty) {
        return inner;
      }
      return '';
    });

    // Interpolate {variables}
    values.forEach((key, val) {
      result = result.replaceAll('{$key}', val);
    });

    return result;
  }

  void _copyEvaluatedText(String evaluated) {
    Clipboard.setData(ClipboardData(text: evaluated));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copy evaluado copiado al portapapeles.'), duration: Duration(seconds: 2)),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final evaluated = _interpolate(widget.templateContent);
    final charCount = evaluated.length;
    const maxChars = 4096;
    final isOverLimit = charCount > maxChars;

    final v = _selectedVolume ?? widget.volume;
    final s = widget.series;
    final currentBookTitle = v != null
        ? '${v.displayTitle} (Vol. ${v.volume != null ? (v.volume! % 1 == 0 ? v.volume!.toInt() : v.volume) : 1})'
        : 'Alya Sometimes Hides Her Feelings... (Vol. 3.0)';

    final serieEng = (v?.englishTitle.isNotEmpty == true) ? v!.englishTitle : (s?.seriesEnglish ?? 'Alya Sometimes Hides Her Feelings in Russian');
    final serieRom = (s != null && s.name.isNotEmpty) ? s.name : 'Tokidoki Bosotto Russiago de Dereru Tonari no Arya-san';
    final serieSpa = (v?.spanishTitle.isNotEmpty == true) ? v!.spanishTitle : (s?.seriesSpanish ?? 'Alya-san, quien se sienta a mi lado, a veces susurra cosas dulces en ruso');
    final volNum = v?.volume != null ? (v!.volume! % 1 == 0 ? v.volume!.toInt().toString() : v.volume!.toString()) : '3.0';
    final autor = v?.author ?? s?.author ?? 'SunsunSUN';
    final ilustrador = v?.illustrator ?? s?.illustrator ?? 'Momoco';
    final traductor = v?.translator ?? 'Vlady Pasos';
    final editorial = v?.publisher ?? s?.publisher ?? 'Darkness Dragons Translation';
    final sinopsis = v?.description ?? s?.description ?? 'Alisa Mikhailovna Kujou es la "princesa solitaria" de la academia Seirei...';
    final slug = s?.slug ?? 'Tokidoki_Bosotto_Russiago_De_Dereru_Tonari_No_Aryasan';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Control Header Bar (Book Selector, Viewport Toggle, Counter, Copy)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                // Real Book Selector Trigger Button
                InkWell(
                  onTap: () => _showVolumeSearchDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 14, color: Color(0xFF818CF8)),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            currentBookTitle,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC7D2FE)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.search_rounded, size: 13, color: Colors.white38),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // View Switcher (Desktop vs Mobile)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.computer_rounded, size: 14, color: _viewMode == 'desktop' ? Colors.white : Colors.white38),
                        style: IconButton.styleFrom(
                          backgroundColor: _viewMode == 'desktop' ? const Color(0xFF6366F1) : Colors.transparent,
                          padding: const EdgeInsets.all(4),
                          minimumSize: Size.zero,
                        ),
                        tooltip: 'Vista Escritorio',
                        onPressed: () => setState(() => _viewMode = 'desktop'),
                      ),
                      IconButton(
                        icon: Icon(Icons.smartphone_rounded, size: 14, color: _viewMode == 'mobile' ? Colors.white : Colors.white38),
                        style: IconButton.styleFrom(
                          backgroundColor: _viewMode == 'mobile' ? const Color(0xFF6366F1) : Colors.transparent,
                          padding: const EdgeInsets.all(4),
                          minimumSize: Size.zero,
                        ),
                        tooltip: 'Vista Móvil',
                        onPressed: () => setState(() => _viewMode = 'mobile'),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Character Counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverLimit ? Colors.red.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isOverLimit ? Colors.redAccent : Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    '$charCount / $maxChars caracteres',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: isOverLimit ? Colors.redAccent : Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Copy button
                InkWell(
                  onTap: () => _copyEvaluatedText(evaluated),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_copied ? Icons.check : Icons.copy_rounded, size: 12, color: _copied ? Colors.greenAccent : Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copiado' : 'Copiar',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _copied ? Colors.greenAccent : Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Simulator Body (Telegram Channel Message)
          Expanded(
            child: Container(
              color: const Color(0xFF0E1621),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: Container(
                  width: _viewMode == 'desktop' ? 440 : 340,
                  decoration: BoxDecoration(
                    color: const Color(0xFF17212B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF232E3C)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Attached Cover
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: SizedBox(
                          height: _viewMode == 'desktop' ? 240 : 200,
                          child: ZeepubCachedImage(
                            imageUrl: (widget.customCoverUrl != null && widget.customCoverUrl!.isNotEmpty)
                                ? widget.customCoverUrl!
                                : ((v != null && v.coverUrl != null && v.coverUrl!.isNotEmpty)
                                    ? (v.coverUrl!.startsWith('http') ? v.coverUrl! : '${_repo.baseUrl.replaceAll(RegExp(r"/+$"), "")}${v.coverUrl!.startsWith('/') ? v.coverUrl! : '/${v.coverUrl!}'}')
                                    : (v != null && v.bookHash.isNotEmpty ? '${_repo.baseUrl.replaceAll(RegExp(r"/+$"), "")}/api/bot/cover/${v.bookHash}' : '')),
                            baseUrl: _repo.baseUrl,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              color: const Color(0xFF0C1219),
                              child: const Center(
                                child: Icon(Icons.image_rounded, size: 48, color: Colors.white24),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Caption & Content
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Flag Titles
                            Row(
                              children: [
                                const Text('🇬🇧 ', style: TextStyle(fontSize: 13)),
                                Expanded(
                                  child: Text(
                                    serieEng,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Text('🇯🇵 ', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    serieRom,
                                    style: const TextStyle(color: Color(0xFF8FA0B5), fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Text('🇪🇸 ', style: TextStyle(fontSize: 12)),
                                Expanded(
                                  child: Text(
                                    serieSpa,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Volume & Genres
                            Row(
                              children: [
                                const Text('📚 ', style: TextStyle(fontSize: 12)),
                                Text('Volumen $volNum', style: const TextStyle(color: Color(0xFF53A6E7), fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              '🏷️ #Comedia #Romance #Escolar',
                              style: TextStyle(color: Color(0xFF5288C1), fontSize: 11),
                            ),

                            const SizedBox(height: 10),

                            // Ficha Técnica Accordion
                            InkWell(
                              onTap: () => setState(() => _showFicha = !_showFicha),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF242F3D),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_showFicha ? Icons.arrow_drop_down : Icons.arrow_right, color: Colors.white70, size: 18),
                                    const SizedBox(width: 4),
                                    const Text('📋 Ficha Técnica', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            if (_showFicha)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _fieldRow('Autor', autor),
                                    const SizedBox(height: 3),
                                    _fieldRow('Ilustrador', ilustrador),
                                    const SizedBox(height: 3),
                                    _fieldRow('Categoría', 'Novela Ligera'),
                                    const SizedBox(height: 3),
                                    _fieldRow('Traductor', traductor),
                                    const SizedBox(height: 3),
                                    _fieldRow('Editorial', editorial),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 6),

                            // Sinopsis Accordion
                            InkWell(
                              onTap: () => setState(() => _showSinopsis = !_showSinopsis),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF242F3D),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(_showSinopsis ? Icons.arrow_drop_down : Icons.arrow_right, color: Colors.white70, size: 18),
                                    const SizedBox(width: 4),
                                    const Text('📖 Ver Sinopsis', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                            if (_showSinopsis)
                              Container(
                                margin: const EdgeInsets.only(top: 4, left: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  border: Border(left: BorderSide(color: Color(0xFF53A6E7), width: 3)),
                                  color: Color(0xFF202B36),
                                ),
                                child: Text(
                                  sinopsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                                ),
                              ),

                            const SizedBox(height: 10),

                            // EPUB Document Bubble
                            if (widget.sendAsFile)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF242F3D),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF53A6E7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$serieSpa - V$volNum.epub',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text('14.1 MB · EPUB 3.0', style: TextStyle(color: Color(0xFF708499), fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 8),

                            // Hashtag & Timestamp
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('#$slug', style: const TextStyle(color: Color(0xFF53A6E7), fontSize: 11)),
                                const Row(
                                  children: [
                                    Text('12:15', style: TextStyle(color: Color(0xFF708499), fontSize: 10)),
                                    SizedBox(width: 4),
                                    Icon(Icons.done_all, size: 14, color: Color(0xFF53A6E7)),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(color: Color(0xFF708499), fontSize: 11)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
