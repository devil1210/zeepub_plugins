import 'widgets/zeepub_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/features/zeepub_editorial/data/models/zeepub_channel.dart';
import '/features/zeepub_editorial/data/models/zeepub_series.dart';
import '/features/zeepub_editorial/data/models/zeepub_template.dart';
import '/features/zeepub_editorial/data/models/zeepub_volume.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_cubit.dart';
import '/features/zeepub_editorial/presentation/cubit/zeepub_editorial_state.dart';
import 'widgets/telegram_simulator.dart';

class ZeepubPublisherView extends StatefulWidget {
  final ZeepubVolume volume;
  final String baseUrl;
  final VoidCallback onBack;

  const ZeepubPublisherView({
    super.key,
    required this.volume,
    required this.baseUrl,
    required this.onBack,
  });

  @override
  State<ZeepubPublisherView> createState() => _ZeepubPublisherViewState();
}

class _ZeepubPublisherViewState extends State<ZeepubPublisherView> {
  ZeepubChannel? _selectedChannel;
  ZeepubTemplate? _selectedTemplate;
  late final TextEditingController _captionController;
  bool _publishNow = true;
  DateTime _scheduledDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _scheduledTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
  bool _sendAsFile = true;

  final List<String> _variables = [
    '{serie}',
    '{volumen}',
    '{titulo}',
    '{autor}',
    '{illustrator}',
    '{traductor}',
    '{editorial}',
    '{sinopsis}',
    '{demography}',
    '{genres}',
    '{tomoid}',
    '{fecha}',
    '{published_at}',
    '{slug}',
    '{download_link}',
    '{layout_by}',
  ];

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ZeepubEditorialCubit>();
      cubit.loadChannels();
      cubit.loadTemplates();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _insertTag(String tag) {
    final text = _captionController.text;
    final selection = _captionController.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, tag);
    _captionController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + tag.length),
    );
    setState(() {});
  }

  void _wrapTag(String open, String close) {
    final text = _captionController.text;
    final selection = _captionController.selection;
    if (selection.start >= 0 && selection.end > selection.start) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$open$selectedText$close');
      _captionController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.end + open.length + close.length),
      );
    } else {
      _insertTag('$open$close');
    }
    setState(() {});
  }

  String _buildCoverUrl() {
    final cleanBase = widget.baseUrl.replaceAll(RegExp(r"/+$"), "");
    if (widget.volume.coverUrl != null && widget.volume.coverUrl!.isNotEmpty) {
      if (widget.volume.coverUrl!.startsWith('http')) return widget.volume.coverUrl!;
      final cleanPath = widget.volume.coverUrl!.startsWith('/') ? widget.volume.coverUrl! : '/${widget.volume.coverUrl!}';
      return '$cleanBase$cleanPath';
    }
    if (widget.volume.bookHash.isNotEmpty) {
      return '$cleanBase/api/bot/cover/${widget.volume.bookHash}';
    }
    return '';
  }

  Future<void> _handlePublish(ZeepubEditorialCubit cubit) async {
    final customCaption = _captionController.text.trim();

    if (_publishNow) {
      await cubit.publishNow(
        bookHash: widget.volume.bookHash,
        channelId: _selectedChannel?.id,
        templateId: _selectedTemplate?.id,
        customCaption: customCaption.isNotEmpty ? customCaption : null,
        sendAsFile: _sendAsFile,
      );
    } else {
      final dt = DateTime(
        _scheduledDate.year,
        _scheduledDate.month,
        _scheduledDate.day,
        _scheduledTime.hour,
        _scheduledTime.minute,
      );
      await cubit.schedulePublication(
        bookHash: widget.volume.bookHash,
        scheduledAtIso: dt.toUtc().toIso8601String(),
        channelId: _selectedChannel?.id,
        templateId: _selectedTemplate?.id,
        customCaption: customCaption.isNotEmpty ? customCaption : null,
        sendAsFile: _sendAsFile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final coverUrl = _buildCoverUrl();

    return BlocConsumer<ZeepubEditorialCubit, ZeepubEditorialState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green.shade800,
            ),
          );
          widget.onBack();
        }
      },
      builder: (context, state) {
        final cubit = context.read<ZeepubEditorialCubit>();
        final channels = state.channels;
        final templates = state.templates;

        if (channels.isNotEmpty && _selectedChannel == null) {
          _selectedChannel = channels.firstWhere((c) => c.isDefault, orElse: () => channels.first);
        }

        if (templates.isNotEmpty && _selectedTemplate == null) {
          _selectedTemplate = templates.firstWhere((t) => t.isDefault, orElse: () => templates.first);
          if (_captionController.text.isEmpty && _selectedTemplate != null) {
            _captionController.text = _selectedTemplate!.content;
          }
        }

        final ZeepubSeries? series = state.seriesList.cast<ZeepubSeries?>().firstWhere(
              (s) => s != null && (s.id == widget.volume.seriesId || s.name == widget.volume.seriesName),
              orElse: () => null,
            );

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver a Tomos',
              onPressed: widget.onBack,
            ),
            title: Row(
              children: [
                const Icon(Icons.send_rounded, color: Color(0xFF38BDF8)),
                const SizedBox(width: 10),
                Text('Publicador Oficial Telegram · ${widget.volume.title}'),
              ],
            ),
          ),
          body: Row(
            children: [
              // LEFT COLUMN: PUBLISHING CONFIGURATION & EDITOR
              Expanded(
                flex: 5,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // BOOK SUMMARY CARD
                    Card(
                      elevation: 0,
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 52,
                                height: 74,
                                child: ZeepubCachedImage(
                                  imageUrl: coverUrl,
                                  baseUrl: widget.baseUrl,
                                  fit: BoxFit.cover,
                                  fallbackIconSize: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.volume.englishTitle.isNotEmpty ? widget.volume.englishTitle : widget.volume.title,
                                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Volumen ${widget.volume.volume ?? 1} · Fansub: ${widget.volume.publisher ?? "Oficial"}',
                                    style: tt.labelSmall?.copyWith(color: cs.primary),
                                  ),
                                  Text(
                                    'Trad: ${widget.volume.translator ?? "N/A"} · ${widget.volume.filename ?? ""}',
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CHANNEL & TEMPLATE SELECTORS
                    Row(
                      children: [
                        // Channel Dropdown
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedChannel?.id,
                            decoration: const InputDecoration(
                              labelText: 'Canal de Destino',
                              prefixIcon: Icon(Icons.send_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: channels.map((c) {
                              return DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.name.isNotEmpty ? c.name : c.channelId),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id != null) {
                                setState(() {
                                  _selectedChannel = channels.firstWhere((c) => c.id == id);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Template Dropdown
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _selectedTemplate?.id,
                            decoration: const InputDecoration(
                              labelText: 'Plantilla Editorial',
                              prefixIcon: Icon(Icons.view_quilt),
                              border: OutlineInputBorder(),
                            ),
                            items: templates.map((t) {
                              return DropdownMenuItem<int>(
                                value: t.id,
                                child: Text(t.name),
                              );
                            }).toList(),
                            onChanged: (id) {
                              if (id != null) {
                                final tpl = templates.firstWhere((t) => t.id == id);
                                setState(() {
                                  _selectedTemplate = tpl;
                                  _captionController.text = tpl.content;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // PUBLICATION MODE TABS (NOW vs SCHEDULED)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.flash_on_rounded),
                          label: Text('Publicar Ahora'),
                        ),
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.schedule_rounded),
                          label: Text('Programar Fecha/Hora'),
                        ),
                      ],
                      selected: {_publishNow},
                      onSelectionChanged: (set) => setState(() => _publishNow = set.first),
                    ),
                    const SizedBox(height: 12),

                    // SCHEDULE DATE/TIME PICKERS
                    if (!_publishNow)
                      Card(
                        elevation: 0,
                        color: cs.primaryContainer.withValues(alpha: 0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.calendar_today_rounded),
                                  label: Text('${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, "0")}-${_scheduledDate.day.toString().padLeft(2, "0")}'),
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _scheduledDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) setState(() => _scheduledDate = picked);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.access_time_rounded),
                                  label: Text('${_scheduledTime.hour.toString().padLeft(2, "0")}:${_scheduledTime.minute.toString().padLeft(2, "0")}'),
                                  onPressed: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _scheduledTime,
                                    );
                                    if (picked != null) setState(() => _scheduledTime = picked);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // OPTIONS (SEND AS EPUB DOCUMENT)
                    CheckboxListTile(
                      value: _sendAsFile,
                      title: const Text('Adjuntar archivo EPUB al mensaje'),
                      subtitle: const Text('Envia el documento EPUB real junto con la ficha estructurada'),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _sendAsFile = val ?? true),
                    ),
                    const SizedBox(height: 12),

                    // COPY EDITOR TOOLBAR
                    Text('MENSAJE / CAPTION PERSONALIZADO', style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _formatButton('B', () => _wrapTag('<b>', '</b>')),
                        _formatButton('I', () => _wrapTag('<i>', '</i>')),
                        _formatButton('U', () => _wrapTag('<u>', '</u>')),
                        _formatButton('S', () => _wrapTag('<s>', '</s>')),
                        _formatButton('Cita', () => _wrapTag('<blockquote>', '</blockquote>')),
                        _formatButton('Expandible', () => _wrapTag('<details><summary>Titulo</summary>', '</details>')),
                        _formatButton('H', () => _wrapTag('<h3>', '</h3>')),
                        _formatButton('Enlace', () => _wrapTag('<a href="URL">', '</a>')),
                        _formatButton('Condicional [?]', () => _wrapTag('[?volumen]', '[/?]')),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // VARIABLE CHIPS
                    Text('VARIABLES DINÁMICAS (Haz clic para insertar):', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final v in _variables)
                          ActionChip(
                            label: Text(v, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                            padding: EdgeInsets.zero,
                            onPressed: () => _insertTag(v),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // CAPTION TEXT AREA
                    TextField(
                      controller: _captionController,
                      maxLines: 12,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Plantilla de Texto del Mensaje',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                        hintText: 'Escribe o ajusta el copy para esta publicación...',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ACTION BUTTON
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF38BDF8),
                          foregroundColor: Colors.black,
                        ),
                        icon: state.saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Icon(_publishNow ? Icons.send_rounded : Icons.calendar_month_rounded),
                        label: Text(
                          _publishNow ? 'Publicar Inmediatamente en Canal' : 'Guardar y Programar Publicación',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: state.saving ? null : () => _handlePublish(cubit),
                      ),
                    ),
                  ],
                ),
              ),

              // RIGHT COLUMN: TELEGRAM DESKTOP SIMULATOR (LIVE PREVIEW)
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TelegramSimulator(
                    templateContent: _captionController.text,
                    volume: widget.volume,
                    series: series,
                    channel: _selectedChannel,
                    customCoverUrl: coverUrl,
                    sendAsFile: _sendAsFile,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _formatButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
